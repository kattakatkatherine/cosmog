local discordia = require('discordia')
local json = require('json')
local client = discordia.Client()

--[[
	Cosmog
	by Katherine Gearhart
	Summer 2020

	Made with Discordia
	https://github.com/SinisterRectus/Discordia/wiki
]]

client:on('ready', function()

	--configure bot
	local file = io.open('config.json', 'r')
	local decoded = json.decode(file:read('*a'))
	botName = decoded['Name']
	client:setUsername(botName)
	client:setAvatar(decoded['Avatar'])
	client:setGame(decoded['Status'])
	botPrefix = decoded['Prefix']
	file:close()

	print('Logged in as ' .. botName)

	entry = {
		ping = {content = 'Pong!', type = 'message', alias = 'pong', description = 'Checks to see if ' .. botName .. ' is online.', usage = 'ping'},
		info = {type = 'embed', description = 'Gets ' .. botName .. '\'s information.', usage = 'info'},
		help = {type = 'embed', description = 'Gets a list of commands.', usage = 'help (command)'},
		invite = {content = 'https://discord.com/api/oauth2/authorize?client_id=711547275410800701&permissions=8&scope=bot', type = 'message', description = 'Grabs ' .. botName .. '\'s invite link.', usage = 'invite'},
		say = {type = 'message', alias = 'echo', description = 'Says something.', usage = 'say [text]'},
		avatar = {type = 'embed', alias = 'pfp', description = 'Gets a user\'s profile picture.', usage = 'avatar (mention)'},
		emote = {alias = 'emoji', description = 'Gets an emote as an image.', usage = 'emote [emote]'},
		random = {type = 'message', alias = 'rand', description = 'Gets a random number between two integers.', usage = 'random [integer], [integer]'},
		pick = {type = 'message', alias = 'choose', description = 'Picks between multiple options.', usage = 'pick [option] or [option]'},
		server = {alias = 'guild', description = 'Gets information about the server.', usage = 'server (option)', note = 'Options include \"icon,\" \"banner,\" \"splash,\" \"owner,\" \"members,\" \"name,\" and \"age.\"'},
		poll = {alias = 'vote', description = 'Creates a poll.', usage = 'poll {[question]} {[option]} {[option]}...'},
		prefix = {type = 'message', description = 'Changes ' .. botName .. '\'s prefix.', usage = 'prefix [option]', perms = 8},
		welcome = {type = 'message', description = 'Configures a welcome message.', usage = 'welcome [channel] [message]', note = '\"$server$\" and \"$user$\" are replaced with the server name and the new user, respectively.', perms = 8},
		remind = {type = 'message', alias = 'reminder', description = 'Sets a reminder.', usage = 'remind [duration][h/m/s] (message)'},
		filter = {description = 'Manages the list of filtered words.', usage = 'filter [option] (word)', note = 'Options include \"add,\" \"remove,\" \"list,\" and \"clear.\"', perms = 8},
		coin = {type = 'message', alias = 'flip', description = 'Flips a coin.', usage = 'coin'},
		dice = {type = 'message', alias = 'roll', description = 'Rolls dice.', usage = 'dice ((number of dice)[d][number of faces])', note =  'The default roll is 1d6.'},
		blank = {type = 'message', description = '', usage = ''} --left blank
	}

--alphabetize
	entryOrdered = {}
	for key, val in pairs(entry) do
		table.insert(entryOrdered, val)
		entryOrdered[table.maxn(entryOrdered)]['command'] = key
	end
	table.sort(entryOrdered, function(a,b)
		return a['command'] < b['command']
	end)
end)

client:on('messageCreate', function(message)

	--generate random numbers
	math.randomseed(os.time())
	math.random(); math.random(); math.random()

	--delete words with filtered terms
	filterList = read(message.guild.id, 'filter', false)
	if filterList then
		for key, val in pairs(filterList) do
			if message.content:lower():find(val:lower()) and not message.member:hasPermission(8) then
				message:delete()
			end
		end
	else
		filterList = {}
		write(message.guild.id, 'filter', {})
	end

	--do not respond to bots
	if message.author.bot then
		return
	end

	--check prefix
	currentPrefix = read(message.guild.id, 'prefix', botPrefix)

	--determine command
	for key, val in pairs(entry) do
		if message.content:find('^' .. currentPrefix .. key) or val['alias'] and message.content:find('^' .. currentPrefix .. val['alias']) then

			--check permissions
			if val['perms'] then
				if not message.member:hasPermission(val['perms']) then
					val['type'] = 'message'
					val['content'] = 'You do not have the necessary permissions to use this command.'
					output(key, message.channel, message)
					return
				end
			end

			--allow for accidental double spaces
			local cleanContent = message.content:gsub('  ', ' ')
			while cleanContent:find('  ') do
				cleanContent = cleanContent:gsub('  ', ' ')
			end
			cleanContent = cleanContent:match('%s(.*)$')

			--dynamic commands
			if key == 'info' then
				info(tostring(#client.guilds), client:getUser(client.user.id):getAvatarURL() .. '?size=1024')
			elseif key == 'help' then
				help(cleanContent)
			elseif key == 'say' then
				say(cleanContent, message)
			elseif key == 'avatar' then
				avatar(message.mentionedUsers.first, message.author)
			elseif key == 'emote' then
				emote(message.mentionedEmojis.first, cleanContent)
			elseif key == 'random' then
				random(cleanContent)
			elseif key == 'pick' then
				pick(cleanContent)
			elseif key == 'server' then
				server(cleanContent, message.guild)
			elseif key == 'poll' then
				poll(cleanContent, message)
			elseif key == 'prefix' then
				prefix(cleanContent, message.guild.id, message.guild:getMember(client.user.id), message.mentionedUsers.first, message.mentionedEmojis.first, message.mentionedChannels.first)
			elseif key == 'welcome' then
				welcome(message.mentionedChannels.first, cleanContent, message.guild.id)
			elseif key == 'remind' then
				remind(cleanContent, message.author.mentionString, message)
			elseif key == 'filter' then
				filter(message.guild.id, cleanContent)
			elseif key == 'coin' then
				coin()
			elseif key == 'dice' then
				dice(cleanContent)
			end

			--send message
			output(key, message.channel, message)
			return
		end
	end
end)

--send welcome message
client:on('memberJoin', function(member)
	welcomeChannel = read(member.guild.id, 'welcomeChannel', nil)
	welcomeMessage = read(member.guild.id, 'welcomeMessage', nil)
	if welcomeChannel then
		entry['blank']['type'] = 'message'
		entry['blank']['content'] = welcomeMessage:gsub('%$server%$', member.guild.name):gsub('%$user%$', member.user.mentionString)
		output('blank', client:getChannel(welcomeChannel), nil)
	end
end)

--restore nickname upon rejoining a server
client:on('guildCreate', function(guild)
	nickManage(guild:getMember(client.user.id))
end)

function info(servers, pfp)
	entry['info']['content'] = {
		title = botName:gsub('^%l', string.upper),
		thumbnail = {url = pfp},
		description = 'A general-purpose bot with a variety of useful commands.\nCurrently in ' .. servers .. ' servers.',
		footer = {text = 'Created by kat#8931 <3'}
	}
end

function help(content)
	if content then
		local tfields = {}
		for key, val in pairs(entry) do
			if content:find('^' .. key) or val['alias'] and content:find('^' .. val['alias']) then
				ttitle = key:gsub('^%l', string.upper)
				tfields[1] = {name = 'Description', value = val['description'], inline = false}
				tfields[2] = {name = 'Usage', value = currentPrefix .. val['usage'], inline = false}
				if val['note'] then
					tfields[3] = {name = 'Note', value = val['note'], inline = false}
				end
				if val['alias'] then
					table.insert(tfields, {name = 'Alias', value = val['alias'], inline = false})
				end
				entry['help']['content'] = {title = ttitle, fields = tfields}
				return
			elseif key == table.maxn(entry) then
				helpSummary()
			end
		end
	else
		helpSummary()
	end
end

function helpSummary()
	entry['help']['content'] = {title = 'Help', fields = {}, footer = {text = 'Use ' .. currentPrefix .. 'help [command] to learn more.'}}
	local i = 0
	for key, val in ipairs(entryOrdered) do
		if val['command'] ~= 'blank' then
			i = i + 1
			entry['help']['content']['fields'][i] = {name = val['command'], value = val['description'], inline = false}
		end
	end
end

function say(content, message)
	if content then
		entry['say']['content'] = content
		message:delete()
	else
		entry['say']['content'] = 'What should I say?'
	end
end

function avatar(mention, author)
	local target = author
	if mention then
		target = mention
	end
	entry['avatar']['content'] = {image = {url = target:getAvatarURL() .. '?size=1024'}}
end

function emote(emote, content)
	if emote then
		entry['emote']['type'] = 'embed'
		entry['emote']['content'] = {image = {url = emote.url}}
	else
		entry['emote']['type'] = 'message'
		if content then
			entry['emote']['content'] = 'I can only grab custom emotes that are on this server.'
		else
			entry['emote']['content'] = 'Which emote should I grab?'
		end
	end
end

function random(content)
	if content and content:find('%d+.*,.*%d+') then
		entry['random']['content'] = math.random(content:match('%-?%d+'), content:match(',.-(%-?%d+)'))
	else
		entry['random']['content'] = 'What range would you like to use?'
	end
end

function pick(content)
	if content then
		local options = {}
		while content:find(' or ') do
			table.insert(options, content:match('^(.-) or '))
			content = content:match(' or (.*)$')
		end
		table.insert(options, content)
		entry['pick']['content'] = 'I pick... ' .. options[math.random(#options)]
	else
		entry['pick']['content'] = 'Make sure to separate the options with \"or.\"'
	end
end

function server(content, server)
	entry['server']['type'] = 'message'
	if content then

		local tentry = {
			icon = {type = 'image', content = server.iconURL, fail = 'an icon'},
			banner = {type = 'image', content = server.bannerURL, fail = 'a banner'},
			splash = {type = 'image', content = server.splashURL, fail = 'a splash image'},
			owner = {type = 'message', content = server.owner.user.tag:gsub('^%l', string.upper) .. ' owns this server.'},
			member = {type = 'message', content = tostring(server.totalMemberCount) .. ' users are in this server.'},
			name = {type = 'message', content = 'This server is called ' .. server.name .. '.'},
			age = {type = 'message', content = os.date('This server was created on %b %d, %Y at %H:%M.', server.createdAt)},
		}

		for key, val in pairs(tentry) do
			if content:find('^' .. key) then
				if val['content'] then
					if val['type'] == 'image' then
						entry['server']['type'] = 'embed'
						entry['server']['content'] = {image = {url = val['content'] .. '?size=1024'}}
					elseif val['type'] == 'message' then
						entry['server']['content'] = val['content']
					end
				else
					entry['server']['content'] = 'It doesn\'t look like this server has ' .. val['fail'] .. '...'
				end
				return
			elseif key == table.maxn(tentry) then
				serverSummary(server)
			end
		end
	else
		serverSummary(server)
	end
end

function serverSummary(server)
	entry['server']['type'] = 'embed'
	entry['server']['content'] = {
		title = server.name,
		thumbnail = {},
		description = 'This server is owned by ' .. server.owner.user.tag .. '.\n It currently has ' .. tostring(server.totalMemberCount) .. ' members.'
	}
	if server.iconURL then
		entry['server']['content']['thumbnail'] = {url = server.iconURL}
	end
end

function poll(content, message)
	entry['poll']['code'] = 0
	entry['poll']['type'] = 'message'
	if content and content:find('{.*}') then
		local question = content:match('{(.-)}')
		content = content:match('}(.*)$')
		local i = 0
		local options = ''
		emotes = {'🇦','🇧','🇨','🇩','🇪','🇫','🇬','🇭','🇮','🇯','🇰','🇱','🇲','🇳','🇴','🇵','🇶','🇷','🇸','🇹'}

		while content:find('{.*}') and i <= 20 do
			i = i + 1
			options = options .. '\n\n'..emotes[i] .. ' ' .. content:match('{(.-)}')
			content = content:match('}(.*)$')
			entry['poll']['code'] = i
		end

		message:delete()
		entry['poll']['type'] = 'embed'
		entry['poll']['content'] = {title = question, description = options}
	else
		entry['poll']['content'] = 'Please surround the question with curly brackets.'
	end
end

function prefix(content, server, bot, user, emoji, channel)
	if user then
		entry['prefix']['content'] = 'You can\'t use a user mention in your prefix.'
	elseif emoji then
		entry['prefix']['content'] = 'You can\'t use an emoji in your prefix.'
	elseif channel then
		entry['prefix']['content'] = 'You can\'t use a channel mention in your prefix.'
	elseif content then
		currentPrefix = write(server, 'prefix', content)
		entry['prefix']['content'] = 'Changed this server\'s prefix to ' .. currentPrefix
		nickManage(bot)
	else
		entry['prefix']['content'] = 'What would you like this server\'s prefix to be?'
	end
end

function welcome(channel, content, server)
	if channel then
			local welcomeSegment1, welcomeSegment2 = content:match('^%s*(.-)%s*' .. channel.mentionString .. '%s*(.*)$')
			if #welcomeSegment1 + #welcomeSegment2 == 0 then
				entry['welcome']['content'] = 'What message would you like me to send?'
			else
				if not welcomeSegment1 then welcomeSegment1 = '' end
				if not welcomeSegment2 then welcomeSegment2 = '' end
				welcomeChannel = write(server, 'welcomeChannel', channel.id)
				welcomeMessage = write(server, 'welcomeMessage', welcomeSegment1 .. welcomeSegment2)
				entry['welcome']['content'] = 'The welcome message has been set.'
			end
	else
		entry['welcome']['content'] = 'What channel would you like me to send the message in?'
	end
end

function remind(content, mention, message)
	if content and content:find('%d+%.?%d*[hms]') then
		local timer = require('timer')
		entry['remind']['content'] = 'Your reminder has been set!'
		output('remind', message.channel, message, message.guild:getMember(client.user.id))

		local duration = {'h', 'm', 's'}
		for key, val in pairs(duration) do
			val = content:match('(%d+%.?%d*)[' .. val .. ']')
			if not val then
				val = 0
			end
		end
		local text = content:match('^(.-)%s*%d+%.?%d*[hms]') .. content:match('%d+%.?%d*[hms]%s*(.-)$')
		if not text then
			text = ''
		end

		timer.sleep(duration[1] * 3600000 + duration[2] * 60000 + duration[3] * 1000)
		entry['remind']['content'] = '**Reminder** ' .. mention .. ' '.. text
	else
		entry['remind']['content'] = 'When would you like me to remind you?'
	end
end

function filter(server, content, channel)
	filterList = read(server, 'filter', false)
	entry['filter']['type'] = 'message'
	if content then
		if content:find('^add ') then
			table.insert(filterList, content:match('^add (.*)$'):lower())
			entry['filter']['content'] = 'The above word has been added to the filter list.'
		elseif content:find('^remove ') then
			local removeWord = content:match('^remove (.*)$'):lower()
			for key, val in pairs(filterList) do
				if removeWord == val then
					table.remove(filterList, key)
					entry['filter']['content'] = '\"' .. removeWord:gsub('^%l', string.upper) .. '\" has been removed from the filter list.'
				elseif key == table.maxn(filterList) then
					entry['filter']['content'] = 'It appears that \"' .. removeWord .. '\" is not on the filter list.'
				end
			end
		elseif content:find('^list') then
			entry['filter']['content'] = {title = 'Filtered Words', description = ''}
			entry['filter']['type'] = 'embed'
			for key, val in pairs(entry) do
				entry['filter']['content']['description'] = entry['filter']['content']['description'] .. '\n' .. val
			end
		elseif content:find('^clear') then
			filterList = {}
			entry['filter']['content'] = 'The filter list has been cleared.'
		else
			entry['filter']['content'] = 'Please choose an option.'
		end
	else
		entry['filter']['content'] = 'Please choose an option.'
	end
	write(server, 'filter', filterList)
end

function coin()
	local result = 'heads ' .. client:getEmoji('717821936163356723').mentionString
	if math.random(0, 1) == 0 then
		result = 'tails ' .. client:getEmoji('717821935924543560').mentionString
	end
	entry['coin']['content'] = 'You got... ' .. result
end

function dice(content)
	local diceCount = 1
	local diceType = 6
	local sum = 0
	if content and content:find('%d*d%d+') then
		if content:find('%d+d') then
			content = content:match('%d+.*')
			diceCount = content:match('%d+')
		end
		content = content:sub(content:find('d') + 1)
		diceType = content:match('%d+')
	end
	for i = 1, diceCount, 1 do
		sum = sum + math.random(diceType)
	end
	entry['dice']['content'] = 'You got... ' .. sum .. ' 🎲'
end

--send the message
function output(key, channel, message, bot)
	local sentID
	if entry[key]['type'] == 'message' then
		sentID = channel:send(entry[key]['content'])
	elseif entry[key]['type'] == 'embed' then
		entry[key]['content']['color'] = discordia.Color.fromRGB(32, 102, 148).value
		sentID = channel:send{embed = entry[key]['content']}
	end
	if key == 'poll' and message then
		pollReact(message, sentID)
	end
end

--writes to config file
function write(server, option, content)
	local file = io.open('servers.json', 'r')
	local search = file:read('*a')
	file:close()
	local decoded = json.decode(search)

	if not decoded[server] then
		decoded[server] = {}
	end

	decoded[server][option] = content
	local encoded = json.encode(decoded)
	local file = io.open('servers.json', 'w+')
	file:write(encoded)
	file:close()
	return content
end

--reads from config file
function read(server, option, default)
	local file = io.open('servers.json', 'r')
	local decoded = json.decode(file:read('*a'))
	local variable = default

	if decoded[server] and decoded[server][option] then
		variable = decoded[server][option]
	end

	file:close()
	return variable
end

--$prefix changes bot's nickname
function nickManage(bot)
	local nickname = nil
	if currentPrefix ~= botPrefix then
		nickname = botName .. ' [' .. currentPrefix .. ']'
	end
	bot:setNickname(nickname)
end

--$poll deletes the initial message and adds reactions
function pollReact(message, sentID)
	if entry['poll']['code'] > 0 then
		for i = 1, entry['poll']['code'], 1 do
			sentID:addReaction(emotes[i])
		end
	end
end

--run
client:run('Bot ' .. json.decode(io.open('config.json', 'r'):read('*a'))['Token'])
