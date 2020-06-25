local discordia = require 'discordia'
local json = require 'json'
local timer = require 'timer'
local client = discordia.Client()

--[[
	Cosmog
	Katherine Gearhart
	June 2020
]]

client:on('ready', function()

	-- configure bot
	local file = io.open('config.json', 'r')
	local decoded = json.decode(file:read('*a'))
	botName = decoded.Name
	client:setUsername(botName)
	client:setAvatar(decoded.Avatar)
	client:setGame(decoded.Status)
	botPrefix = decoded.Prefix
	botColor = discordia.Color.fromHex(decoded.Color).value
	file:close()

	entry = {
		ping = {content = 'Pong!', type = 'message', alias = 'pong', description = 'Checks to see if ' .. botName .. ' is online.', usage = 'ping'},
		info = {type = 'embed', description = 'Gets ' .. botName .. '\'s information.', usage = 'info', ftn = info},
		help = {type = 'embed', description = 'Gets a list of commands.', usage = 'help (command)', ftn = help},
		invite = {content = 'https://discord.com/api/oauth2/authorize?client_id=711547275410800701&permissions=8&scope=bot', type = 'message', description = 'Gets ' .. botName .. '\'s invite link.', usage = 'invite'},
		say = {type = 'message', alias = 'echo', description = 'Says something.', usage = 'say [text]', ftn = say},
		user = {type = 'embed', alias = 'member', description = 'Gets information about a user.', usage = 'user (mention) (option)', note = 'Options include \"avatar,\" \"join,\" and \"age.\"', ftn = user},
		emote = {alias = 'emoji', description = 'Gets an emote as an image.', usage = 'emote [emote]', ftn = emote},
		random = {type = 'message', alias = 'rand', description = 'Gets a random number between two integers.', usage = 'random [integer], [integer]', ftn = random},
		pick = {type = 'message', alias = 'choose', description = 'Picks between multiple options.', usage = 'pick [option] or [option] . . .', ftn = pick},
		server = {alias = 'guild', description = 'Gets information about the server.', usage = 'server (option)', note = 'Options include \"icon,\" \"banner,\" \"splash,\" \"owner,\" \"members,\" \"name,\" and \"age.\"', ftn = server},
		poll = {alias = 'vote', description = 'Creates a poll.', usage = 'poll {[question]} {[option]} {[option]} . . .', ftn = poll},
		prefix = {type = 'message', description = 'Changes ' .. botName .. '\'s prefix.', usage = 'prefix [option]', perms = 'administrator', ftn = prefix},
		welcome = {description = 'Configures a welcome message.', usage = 'welcome [option] (arguments)', note = 'Options include \"set,\" \"current,\" and \"clear.\" \"$server$\" and \"$user$\" are replaced with the server name and the new user, respectively.', perms = 'administrator', ftn = welcome},
		remind = {type = 'message', alias = 'reminder', description = 'Sets a reminder.', usage = 'remind [duration][h/m/s] (message)', ftn = remind},
		filter = {description = 'Manages the list of filtered words.', usage = 'filter [option] (word)', note = 'Options include \"add,\" \"remove,\" \"list,\" and \"clear.\"', perms = 'manageMessages', ftn = filter},
		coin = {type = 'message', alias = 'flip', description = 'Flips a coin.', usage = 'coin', ftn = coin},
		dice = {type = 'message', alias = 'roll', description = 'Rolls dice.', usage = 'dice ((number of dice)[d][number of faces])', note = 'The default roll is 1d6.', ftn = dice},
		purge = {type = 'message', alias = 'bulk', description = 'Bulk deletes messages.', usage = 'purge [number of messages]', note = 'This command cannot delete messages older than two weeks.', perms = 'manageMessages', ftn = purge}
	}

	-- alphabetize
	entryOrdered = {}
	for key, val in pairs(entry) do
		table.insert(entryOrdered, val)
		entryOrdered[table.maxn(entryOrdered)].command = key
	end
	table.sort(entryOrdered, function(a,b)
		return a.command < b.command
	end)

	-- entry for non-command outputs
	entry.blank = {type = 'message', description = '', usage = ''}

	print('Logged in as ' .. botName .. '.')
end)

client:on('messageCreate', function(message)

	-- respond only if in a server
	if not message.guild then
		return
	end

	-- delete messages with filtered terms
	filterList = read(message.guild.id, 'filter')
	if filterList then
		for _, val in pairs(filterList) do
			if message.content:lower():find(val) and not message.member:hasPermission('administrator') then
				message:delete()
				return
			end
		end
	else
		filterList = {}
		write(message.guild.id, 'filter', {})
	end

	-- do not respond to bots
	if message.author.bot then
		return
	end

	-- check prefix
	currentPrefix = read(message.guild.id, 'prefix', botPrefix)

	-- determine command
	for key, val in pairs(entry) do
		if message.content:find('^' .. currentPrefix .. key) or val.alias and message.content:find('^' .. currentPrefix .. val.alias) then

			-- check permissions
			if val.perms and not message.member:hasPermission(val.perms) then
				val.type = 'message'
				val.content = 'You do not have the necessary permissions to use this command.'
				output(key, message.channel, message)
				return
			end

			-- generate random numbers
			math.randomseed(os.time())
			math.random(); math.random(); math.random()

			-- format message content
			local cmd = key
			if not message.content:find('^' .. currentPrefix .. key) then
				cmd = val.alias
			end
			cleanContent = message.content:gsub('%s+', ' '):match(cmd .. '%s*(.*)$')
			if not cleanContent then
				cleanContent = ''
			end

			-- dynamic commands
			if val.ftn then
				val.ftn(cleanContent, message, cleanContent:lower())
			end

			-- send message
			output(key, message.channel, message)
			return
		end
	end
end)

-- send welcome message
client:on('memberJoin', function(member)
	welcomeChannel = read(member.guild.id, 'welcomeChannel')
	welcomeMessage = read(member.guild.id, 'welcomeMessage')
	if welcomeChannel and welcomeMessage then
		entry.blank.type = 'message'
		entry.blank.content = welcomeMessage:gsub('%$server%$', member.guild.name):gsub('%$user%$', member.user.mentionString)
		output('blank', client:getChannel(welcomeChannel))
	end
end)

-- restore nickname upon rejoining a server
client:on('guildCreate', function(guild)
	nickManage(guild:getMember(client.user.id))
end)

function info()
	entry.info.content = {
		title = botName:gsub('^%l', string.upper),
		thumbnail = {url = client:getUser(client.user.id):getAvatarURL() .. '?size=1024'},
		description = 'A general-purpose bot with a variety of useful commands.\nCurrently in ' .. tostring(#client.guilds) .. ' servers.',
		footer = {text = 'Made by kat#8931 <3'}
	}
end

function help(_, _, content)
	local tfields = {}
	for key, val in pairs(entry) do
		if content:find('^' .. key) or val.alias and content:find('^' .. val.alias) then
			ttitle = key:gsub('^%l', string.upper)
			table.insert(tfields, {name = 'Description', value = val.description})
			table.insert(tfields, {name = 'Usage', value = currentPrefix .. val.usage})
			if val.note then
				table.insert(tfields, {name = 'Note', value = val.note})
			end
			if val.alias then
				table.insert(tfields, {name = 'Alias', value = val.alias})
			end
			entry.help.content = {title = ttitle, fields = tfields}
			return
		end
	end
	entry.help.content = {title = 'Help', fields = {}, footer = {text = 'Use ' .. currentPrefix .. 'help [command] to learn more.'}}
	for key, val in ipairs(entryOrdered) do
		entry.help.content.fields[key] = {name = val.command, value = val.description}
	end
end

function say(content, message)
	if content ~= '' then
		entry.say.content = content
		message:delete()
	else
		entry.say.content = 'What should I say?'
	end
end

function user(_, message, content)
	entry.user.type = 'message'
	local target = message.author
	if message.mentionedUsers.first then
		target = message.mentionedUsers.first
	end

	local options = {
		avatar = {type = 'image', content = target:getAvatarURL(), fail = 'an avatar'},
		age = {type = 'message', content = os.date(target.tag:gsub('^%l', string.upper) .. ' created their account on %b %d, %Y at %H:%M.', target.createdAt)},
		join = {type = 'message', content = os.date(target.tag:gsub('^%l', string.upper) .. ' joined the server on %b %d, %Y at %H:%M.', target.joinedAt)}
	}

	for key, val in pairs(options) do
			if content:find('^' .. key) or content:find(target.id .. '>%s*' .. key) then
				entry.user.type, entry.user.content = optionSet(val)
				return
			end
	end
	entry.user.type = 'embed'
	entry.user.content = {
		title = target.tag:gsub('^%l', string.upper),
		thumbnail = {},
		description = os.date('This account was created on %b %d, %Y at %H:%M.', target.createdAt)
	}
	if target:getAvatarURL() then
		entry.user.content.thumbnail = {url = target:getAvatarURL() .. '?size=1024'}
	end
end

function emote(content, message)
	local emote = message.mentionedEmojis.first
	if emote then
		entry.emote.type = 'embed'
		entry.emote.content = {image = {url = emote.url}}
	else
		entry.emote.type = 'message'
		if content then
			entry.emote.content = 'I can only grab custom emotes that are on this server.'
		else
			entry.emote.content = 'Which emote should I grab?'
		end
	end
end

function random(content)
	if content:find('%d+.*,.*%d+') then
		entry.random.content = math.random(content:match('%-?%d+'), content:match(',.-(%-?%d+)'))
	else
		entry.random.content = 'What range would you like to use?'
	end
end

function pick(content)
	if content ~= '' then
		local options = {}
		while content:find(' or ') do
			table.insert(options, content:match('^(.-) or '))
			content = content:match(' or (.*)$')
		end
		table.insert(options, content)
		entry.pick.content = 'I pick… ' .. options[math.random(#options)]
	else
		entry.pick.content = 'What options should I pick from?'
	end
end

function server(_, message, content)
	server = message.guild
	entry.server.type = 'message'

	local options = {
		icon = {type = 'image', content = server.iconURL, fail = 'an icon'},
		banner = {type = 'image', content = server.bannerURL, fail = 'a banner'},
		splash = {type = 'image', content = server.splashURL, fail = 'a splash image'},
		owner = {type = 'message', content = server.owner.user.tag:gsub('^%l', string.upper) .. ' owns this server.'},
		member = {type = 'message', content = tostring(server.totalMemberCount) .. ' users are in this server.'},
		name = {type = 'message', content = 'This server is called ' .. server.name .. '.'},
		age = {type = 'message', content = os.date('This server was created on %b %d, %Y at %H:%M.', server.createdAt)},
	}

	for key, val in pairs(options) do
		if content:find('^' .. key) then
			entry.server.type, entry.server.content = optionSet(val)
			return
		end
	end
	entry.server.type = 'embed'
	entry.server.content = {
		title = server.name,
		thumbnail = {},
		description = 'This server is owned by ' .. server.owner.user.tag .. '.\nIt currently has ' .. tostring(server.totalMemberCount) .. ' members.'
	}
	if server.iconURL then
		entry.server.content.thumbnail = {url = server.iconURL}
	end
end

function poll(content, message)
	entry.poll.code = 0
	entry.poll.type = 'message'
	if content:find('{.*}') then
		local question = content:match('{(.-)}')
		local options = ''
		emotes = {'🇦','🇧','🇨','🇩','🇪','🇫','🇬','🇭','🇮','🇯','🇰','🇱','🇲','🇳','🇴','🇵','🇶','🇷','🇸','🇹'}

		-- message reactions are limited to 20
		while content:find('}{.*}') and entry.poll.code <= 20 do
			content = content:match('}(.*)$')
			entry.poll.code = entry.poll.code + 1
			options = options .. '\n\n'..emotes[entry.poll.code] .. ' ' .. content:match('{(.-)}')
		end

		message:delete()
		entry.poll.type = 'embed'
		entry.poll.content = {title = question, description = options}
	else
		entry.poll.content = 'Please surround the question with curly brackets.'
	end
end

function prefix(content, message)
	if message.mentionedUsers.first then
		entry.prefix.content = 'You can\'t mention a user in your prefix.'
	elseif message.mentionedEmojis.first then
		entry.prefix.content = 'You can\'t use an emoji in your prefix.'
	elseif message.mentionedChannels.first then
		entry.prefix.content = 'You can\'t mention a channel in your prefix.'
	elseif content ~= '' then
		currentPrefix = write(message.guild.id, 'prefix', content)
		entry.prefix.content = 'Changed this server\'s prefix to ' .. currentPrefix
		nickManage(message.guild:getMember(client.user.id))
	else
		entry.prefix.content = 'What would you like this server\'s prefix to be?'
	end
end

function welcome(content, message)
	local channel, server = message.mentionedChannels.first, message.guild.id
	welcomeChannel = read(server, 'welcomeChannel')
	welcomeMessage = read(server, 'welcomeMessage')
	entry.welcome.type = 'message'
	if content:lower():find('^set') then
		if channel then
			welcomeMessage = content:match('^set%s*(.-)%s*' .. channel.mentionString) .. content:match(channel.mentionString .. '%s*(.*)$')
			if not welcomeMessage or welcomeMessage == '' then
				entry.welcome.content = 'What message would you like me to send?'
				return
			else
				welcomeChannel = channel.id
				entry.welcome.content = 'The welcome message has been set.'
			end
		else
			entry.welcome.content = 'What channel would you like me to send the message in?'
		end
	elseif content:lower():find('^clear') then
		welcomeChannel = nil
		welcomeMessage = nil
		entry.welcome.content = 'The welcome message has been cleared.'
	elseif welcomeChannel and welcomeMessage then
		entry.welcome.type = 'embed'
		entry.welcome.content = {
			title = 'Welcome',
			fields = {
				{name = 'Message', value = welcomeMessage},
				{name = 'Channel', value = '#' .. client:getChannel(welcomeChannel).name}
			}
		}
	else
		entry.welcome.content = 'It doesn\'t look like this server has a welcome message…\nUse `' .. currentPrefix .. 'welcome set [channel] [message]` to make one!'
	end
	write(server, 'welcomeChannel', welcomeChannel)
	write(server, 'welcomeMessage', welcomeMessage)
end

function remind(content, message)
	if content:find('%d+%.?%d*[hms]') then
		entry.remind.content = 'Your reminder has been set!'
		output('remind', message.channel, message, message.guild:getMember(client.user.id))

		local duration = {'h', 'm', 's'}
		for key, val in pairs(duration) do
			duration[key] = content:match('(%d+%.?%d*)' .. val)
			if not duration[key] then
				duration[key] = 0
			end
		end
		local text = content:match('^(.-)%s*%d+%.?%d*[hms]') .. content:match('%d+%.?%d*[hms]%s*(.-)$')
		if not text then
			text = ''
		end

		timer.sleep(duration[1] * 3600000 + duration[2] * 60000 + duration[3] * 1000) -- convert to milliseconds
		entry.remind.content = '**Reminder** ' .. message.author.mentionString .. ' '.. text
	else
		entry.remind.content = 'When would you like me to remind you?'
	end
end

function filter(_, message, content)
	local server = message.guild.id
	filterList = read(server, 'filter', false)
	entry.filter.type = 'message'
	if content:find('^add.*%S') then
		local addWord = content:match('^add%s*(.*)$')
		for key,val in pairs(filterList) do
			if val == addWord then
				entry.filter.content = 'The above word is already on the filter list.'
				return
			end
		end
		table.insert(filterList, addWord)
		entry.filter.content = 'The above word has been added to the filter list.'
	elseif content:find('^add') then
		entry.filter.content = 'What word would you like to add?'
	elseif content:find('^remove.*%S') then
		local removeWord = content:match('^remove%s*(.*)$')
		entry.filter.content = 'It appears that \"' .. removeWord .. '\" is not on the filter list.'
		for key, val in pairs(filterList) do
			if val == removeWord then
				table.remove(filterList, key)
				entry.filter.content = '\"' .. removeWord:gsub('^%l', string.upper) .. '\" has been removed from the filter list.'
				break
			end
		end
	elseif content:find('^remove') then
		entry.filter.content = 'What word would you like to remove?'
	elseif content:find('^clear') then
		filterList = {}
		entry.filter.content = 'The filter list has been cleared.'
	elseif filterList[1] then
		entry.filter.type = 'embed'
		entry.filter.content = {title = 'Filtered Words', description = ''}
		for _, val in pairs(filterList) do
			entry.filter.content.description = entry.filter.content.description .. '\n' .. val
		end
	else
		entry.filter.content = 'It doesn\'t look like this server has a filter list…\nUse `' .. currentPrefix .. 'filter add [word]` to start one!'
	end
	write(server, 'filter', filterList)
end

function coin()
	local result = 'heads ' .. client:getEmoji('717821936163356723').mentionString
	if math.random(2) == 1 then
		result = 'tails ' .. client:getEmoji('717821935924543560').mentionString
	end
	entry.coin.content = 'You got… ' .. result
end

function dice(_, _, content)
	local diceCount, diceType, sum = 1, 6, 0 -- default roll is 1d6
	if content:find('%d*d%d+') then
		if content:find('%d+d') then
			content = content:match('%d+.*')
			diceCount = content:match('%d+')
		end
		content = content:match('d(.*)$')
		diceType = content:match('%d+')
	end
	for i = 1, diceCount do
		sum = sum + math.random(diceType)
	end
	entry.dice.content = 'You got… ' .. sum .. ' 🎲'
end

-- bulk deletions are limited to 100
function purge(content, message)
	local purgeCount = tonumber(content:match('%d+'))
	if purgeCount then
		message:delete()
		entry.purge.content = purgeCount .. ' messages have been deleted.'
		message.channel:bulkDelete(message.channel:getMessages(purgeCount % 100))
		while purgeCount > 100 do
			timer.sleep(100) -- wait for messages to load
			message.channel:bulkDelete(message.channel:getMessages(100))
			purgeCount = purgeCount - 100
		end
	else
		entry.purge.content = 'How many messages should I delete?'
	end
end

-- send the message
function output(key, channel, message, bot)
	local sentID
	if entry[key].type == 'message' then
		sentID = channel:send(entry[key].content)
	elseif entry[key].type == 'embed' then
		entry[key].content.color = botColor
		sentID = channel:send{embed = entry[key].content}
	end
	if key == 'ping' then
		pingCalc(message, sentID)
	elseif key == 'poll' then
		pollReact(message, sentID)
	end
end

-- writes to config file
function write(server, option, content)
	local file = io.open('servers.json', 'r')
	local decoded = json.decode(file:read('*a'))
	file:close()

	if not decoded[server] then
		decoded[server] = {}
	end

	decoded[server][option] = content
	local file = io.open('servers.json', 'w+')
	file:write(json.encode(decoded))
	file:close()
	return content
end

-- reads from config file
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

-- set from an options table
function optionSet(val)
	if val.content then
		if val.type == 'image' then
			return 'embed', {image = {url = val.content .. '?size=1024'}}
		elseif val.type == 'message' then
			return 'message', val.content
		end
	else
		return 'message', 'It doesn\'t look like this server has ' .. val.fail .. '…'
	end
end

-- $prefix changes bot's nickname
function nickManage(bot)
	local nickname
	if currentPrefix ~= botPrefix then
		nickname = botName .. ' [' .. currentPrefix .. ']'
	end
	bot:setNickname(nickname)
end

-- $ping calculates latency
function pingCalc(message, sentID)
	sentID:setContent('Pong! ' .. math.floor(math.abs(sentID.createdAt - message.createdAt) * 1000) .. ' ms')
end

-- $poll adds reactions
function pollReact(message, sentID)
	for i = 1, entry.poll.code do
		sentID:addReaction(emotes[i])
	end
end

-- run
client:run('Bot ' .. json.decode(io.open('config.json', 'r'):read('*a')).Token)
