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
		{command = 'ping', content = 'Pong!', type = 'message', alias = 'pong', description = 'Checks to see if ' .. botName .. ' is online.', usage = 'ping'},
		{command = 'info', type = 'embed', description = 'Gets ' .. botName .. '\'s information.', usage = 'info'},
		{command = 'help', type = 'embed', description = 'Gets a list of commands.', usage = 'help (command)'},
		{command = 'invite', content = 'https://discord.com/api/oauth2/authorize?client_id=711547275410800701&permissions=8&scope=bot', type = 'message', description = 'Grabs ' .. botName .. '\'s invite link.', usage = 'invite'},
		{command = 'say', type = 'message', alias = 'echo', description = 'Says something.', usage = 'say [text]'},
		{command = 'avatar', type = 'embed', alias = 'pfp', description = 'Gets a user\'s profile picture.', usage = 'avatar (mention)'},
		{command = 'emote', alias = 'emoji', description = 'Gets an emote as an image.', usage = 'emote [emote]'},
		{command = 'random', type = 'message', alias = 'rand', description = 'Gets a random number between two integers.', usage = 'random [integer], [integer]'},
		{command = 'pick', type = 'message', alias = 'choose', description = 'Picks between multiple options.', usage = 'pick [option] or [option]'},
		{command = 'server', alias = 'guild', description = 'Gets information about the server.', usage = 'server (option)', note = 'Options include \"icon,\" \"banner,\" \"splash,\" \"owner,\" \"members,\" \"name,\" and \"age.\"'},
		{command = 'poll', alias = 'vote', description = 'Creates a poll.', usage = 'poll {[question]} {[option]} {[option]}'},
		{command = 'prefix', type = 'message', description = 'Changes ' .. botName .. '\'s prefix.', usage = 'prefix [option]', perms = 8},
		{command = 'welcome', type = 'message', description = 'Configures a welcome message.', usage = 'welcome [channel] [message]', note = '\"$server$\" and \"$user$\" are replaced with the server name and the new user, respectively.', perms = 8},
		{command = 'remind', type = 'message', alias = 'reminder', description = 'Sets a reminder.', usage = 'remind [duration][h/m/s] (message)'},
		{command = 'filter', description = 'Manages the list of filtered words.', usage = 'filter [option] (word)', note = 'Options include \"add,\" \"remove,\" \"list,\" and \"clear.\"', perms = 8},
		{command = 'coin', type = 'message', alias = 'flip', description = 'Flips a coin.', usage = 'coin'},
		{command = 'dice', type = 'message', alias = 'roll', description = 'Rolls dice.', usage = 'dice ((number of dice)[d][number of faces])', note =  'The default roll is 1d6.'},
		[0] = {} --left blank
	}

end)

client:on('messageCreate', function(message)

	--generate random numbers
	math.randomseed(os.time())
	math.random(); math.random(); math.random()

	--delete words with filtered terms
	filterList = read(message.guild.id, 'filter', false)
	if filterList then
		for i = 1, table.maxn(filterList), 1 do
			if message.content:lower():find(filterList[i]:lower()) and not message.member:hasPermission(8) then
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
	for i = 1, table.maxn(entry), 1 do
		if message.content:sub(1, #currentPrefix + #entry[i]['command']) == currentPrefix .. entry[i]['command'] or entry[i]['alias'] and message.content:sub(1, #currentPrefix + #entry[i]['alias']) == currentPrefix .. entry[i]['alias'] then

			--check permissions
			if entry[i]['perms'] then
				if not message.member:hasPermission(entry[i]['perms']) then
					entry[i]['type'] = 'message'
					entry[i]['content'] = 'You do not have the necessary permissions to use this command.'
					output(i, message.channel, message)
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
			if i == 2 then
				info(tostring(#client.guilds), client:getUser(client.user.id):getAvatarURL() .. '?size=1024')
			elseif i == 3 then
				help(cleanContent)
			elseif i == 5 then
				say(cleanContent, message)
			elseif i == 6 then
				avatar(message.mentionedUsers.first, message.author)
			elseif i == 7 then
				emote(message.mentionedEmojis.first, cleanContent)
			elseif i == 8 then
				random(cleanContent)
			elseif i == 9 then
				pick(cleanContent)
			elseif i == 10 then
				server(cleanContent, message.guild)
			elseif i == 11 then
				poll(cleanContent, message)
			elseif i == 12 then
				prefix(cleanContent, message.guild.id, message.guild:getMember(client.user.id), message.mentionedUsers.first, message.mentionedEmojis.first, message.mentionedChannels.first)
			elseif i == 13 then
				welcome(message.mentionedChannels.first, cleanContent, message.guild.id)
			elseif i == 14 then
				remind(cleanContent, message.author.mentionString, message)
			elseif i == 15 then
				filter(message.guild.id, cleanContent)
			elseif i == 16 then
				coin()
			elseif i == 17 then
				dice(cleanContent)
			end

			--send message
			output(i, message.channel, message)
			return
		end
	end
end)

--send welcome message
client:on('memberJoin', function(member)
	welcomeChannel = read(member.guild.id, 'welcomeChannel', nil)
	welcomeMessage = read(member.guild.id, 'welcomeMessage', nil)
	if welcomeChannel then
		entry[0]['type'] = 'message'
		entry[0]['content'] = welcomeMessage:gsub('%$server%$', member.guild.name):gsub('%$user%$', member.user.mentionString)
		output(0, client:getChannel(welcomeChannel), nil)
	end
end)

--restore nickname upon rejoining a server
client:on('guildCreate', function(guild)
	nickManage(guild:getMember(client.user.id))
end)

function info(servers, pfp)
	entry[2]['content'] = {
		title = botName:gsub('^%l', string.upper),
		thumbnail = {url = pfp},
		description = 'A general-purpose bot with a variety of useful commands.\nCurrently in ' .. servers .. ' servers.',
		footer = {text = 'Created by kat#8931 <3'}
	}
end

function help(content)
	if content then
		local tfields = {}
		for i = 1, table.maxn(entry), 1 do
			if content:sub(1, #entry[i]['command']) == entry[i]['command'] or entry[i]['alias'] and content:sub(1, #entry[i]['alias']) == entry[i]['alias'] then
				ttitle = entry[i]['command']:gsub('^%l', string.upper)
				tfields[1] = {name = 'Description', value = entry[i]['description'], inline = false}
				tfields[2] = {name = 'Usage', value = currentPrefix .. entry[i]['usage'], inline = false}
				if entry[i]['note'] then
					tfields[3] = {name = 'Note', value = entry[i]['note'], inline = false}
				end
				if entry[i]['alias'] then
					tfields[table.maxn(tfields) + 1] = {name = 'Alias', value = entry[i]['alias'], inline = false}
				end
				entry[3]['content'] = {title = ttitle, fields = tfields}
				return
			elseif i == table.maxn(entry) then
				helpSummary()
			end
		end
	else
		helpSummary()
	end
end

function helpSummary()
	entry[3]['content'] = {title = 'Help', fields = {}, footer = {text = 'Use ' .. currentPrefix .. 'help [command] to learn more.'}}
	for i = 1, table.maxn(entry), 1 do
		entry[3]['content']['fields'][i] = {name = entry[i]['command'], value = entry[i]['description'], inline = false}
	end
end

function say(content, message)
	if content then
		entry[5]['content'] = content
		message:delete()
	else
		entry[5]['content'] = 'What should I say?'
	end
end

function avatar(mention, author)
	local target = author
	if mention then
		target = mention
	end
	entry[6]['content'] = {image = {url = target:getAvatarURL() .. '?size=1024'}}
end

function emote(emote, content)
	if emote then
		entry[7]['type'] = 'embed'
		entry[7]['content'] = {image = {url = emote.url}}
	else
		entry[7]['type'] = 'message'
		if content then
			entry[7]['content'] = 'I can only grab custom emotes that are on this server.'
		else
			entry[7]['content'] = 'Which emote should I grab?'
		end
	end
end

function random(content)
	if content and content:find('%d+.*,.*%d+') then
		entry[8]['content'] = math.random(content:match('%-?%d+'), content:match(',.-(%-?%d+)'))
	else
		entry[8]['content'] = 'What range would you like to use?'
	end
end

function pick(content)
	if content then
		local options = {}
		while content:find(' or ') do
			options[table.maxn(options) + 1] = content:sub(1, content:find(' or '))
			content = content:sub(content:find(' or ') + 4)
		end
		options[table.maxn(options) + 1] = content
		entry[9]['content'] = 'I pick... ' .. options[math.random(1, table.maxn(options))]
	else
		entry[9]['content'] = 'Make sure to separate the options with \"or.\"'
	end
end

function server(content, server)
	entry[10]['type'] = 'message'
	if content then

		local tentry = {
			{option = 'icon', type = 'image', content = server.iconURL, fail = 'an icon'},
			{option = 'banner', type = 'image', content = server.bannerURL, fail = 'a banner'},
			{option = 'splash', type = 'image', content = server.splashURL, fail = 'a splash image'},
			{option = 'owner', type = 'message', content = server.owner.user.tag .. ' owns this server.'},
			{option = 'member', type = 'message', content = tostring(server.totalMemberCount) .. ' users are in this server.'},
			{option = 'name', type = 'message', content = 'This server is called ' .. server.name .. '.'},
			{option = 'age', type = 'message', content = os.date('This server was created on %b %d, %Y at %H:%M.',server.createdAt)},
		}

		for i = 1, table.maxn(tentry), 1 do
			if content:find('^' .. tentry[i]['option']) then
				if tentry[i]['content'] then
					if tentry[i]['type'] == 'image' then
						entry[10]['type'] = 'embed'
						entry[10]['content'] = {image = {url = tentry[i]['content'] .. '?size=1024'}}
					elseif tentry[i]['type'] == 'message' then
						entry[10]['content'] = tentry[i]['content']
					end
				else
					entry[10]['content'] = 'It doesn\'t look like this server has ' .. tentry[i]['fail'] .. '...'
				end
				return
			elseif i == table.maxn(tentry) then
				serverSummary(server)
			end
		end
	else
		serverSummary(server)
	end
end

function serverSummary(server)
	entry[10]['type'] = 'embed'
	entry[10]['content'] = {
		title = server.name,
		thumbnail = {},
		description = 'This server is owned by ' .. server.owner.user.tag .. '.\n It currently has ' .. tostring(server.totalMemberCount) .. ' members.'
	}
	if server.iconURL then
		entry[10]['content']['thumbnail'] = {url = server.iconURL}
	end
end

function poll(content, message)
	entry[11]['code'] = 0
	entry[11]['type'] = 'message'
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
			entry[11]['code'] = i
		end

		message:delete()
		entry[11]['type'] = 'embed'
		entry[11]['content'] = {title = question, description = options}
	else
		entry[11]['content'] = 'Please surround the question with curly brackets.'
	end
end

function prefix(content, server, bot, user, emoji, channel)
	if user then
		entry[12]['content'] = 'You can\'t use a user mention in your prefix.'
	elseif emoji then
		entry[12]['content'] = 'You can\'t use an emoji in your prefix.'
	elseif channel then
		entry[12]['content'] = 'You can\'t use a channel mention in your prefix.'
	elseif content then
		currentPrefix = write(server, 'prefix', content)
		entry[12]['content'] = 'Changed this server\'s prefix to ' .. currentPrefix
		nickManage(bot)
	else
		entry[12]['content'] = 'What would you like this server\'s prefix to be?'
	end
end

function welcome(channel, content, server)
	if channel then
			local welcomeSegment1, welcomeSegment2 = content:match('^%s*(.-)%s*' .. channel.mentionString .. '%s*(.*)$')
			if #welcomeSegment1 + #welcomeSegment2 == 0 then
				entry[13]['content'] = 'What message would you like me to send?'
			else
				if not welcomeSegment1 then welcomeSegment1 = '' end
				if not welcomeSegment2 then welcomeSegment2 = '' end
				welcomeChannel = write(server, 'welcomeChannel', channel.id)
				welcomeMessage = write(server, 'welcomeMessage', welcomeSegment1 .. welcomeSegment2)
				entry[13]['content'] = 'The welcome message has been set.'
			end
	else
		entry[13]['content'] = 'What channel would you like me to send the message in?'
	end
end

function remind(content, mention, message)
	if content and content:find('%d+%.?%d*[hms]') then
		local timer = require('timer')
		entry[14]['content'] = 'Your reminder has been set!'
		output(14, message.channel, message, message.guild:getMember(client.user.id))

		local duration = {'h', 'm', 's'}
		for i = 1, 3, 1 do
			duration[i] = content:match('(%d+%.?%d*)[' .. duration[i] .. ']')
			if not duration[i] then
				duration[i] = 0
			end
		end
		local text = content:match('^(.-)%s*%d+%.?%d*[hms]') .. content:match('%d+%.?%d*[hms]%s*(.-)$')
		if not text then
			text = ''
		end

		timer.sleep(duration[1] * 3600000 + duration[2] * 60000 + duration[3] * 1000)
		entry[14]['content'] = '**Reminder** ' .. mention .. ' '.. text
	else
		entry[14]['content'] = 'When would you like me to remind you?'
	end
end

function filter(server, content, channel)
	filterList = read(server, 'filter', false)
	entry[15]['type'] = 'message'
	if content then
		if content:find('^add ') then
			filterList[table.maxn(filterList) + 1] = content:match('^add (.*)$'):lower()
			entry[15]['content'] = 'The above word has been added to the filter list.'
		elseif content:find('^remove ') then
			local removeWord = content:match('^remove (.*)$'):lower()
			for i = 1, table.maxn(filterList), 1 do
				if removeWord == filterList[i] then
					table.remove(filterList, i)
					entry[15]['content'] = '\"' .. removeWord:gsub('^%l', string.upper) .. '\" has been removed from the filter list.'
				elseif i == table.maxn(filterList) then
					entry[15]['content'] = 'It appears that \"' .. removeWord .. '\" is not on the filter list.'
				end
			end
		elseif content:find('^list') then
			entry[15]['content'] = {title = 'Filtered Words', description = ''}
			entry[15]['type'] = 'embed'
			for i = 1, table.maxn(filterList), 1 do
				entry[15]['content']['description'] = entry[15]['content']['description'] .. '\n' .. filterList[i]
			end
		elseif content:find('^clear') then
			filterList = {}
			entry[15]['content'] = 'The filter list has been cleared.'
		else
			entry[15]['content'] = 'Please choose an option.'
		end
	else
		entry[15]['content'] = 'Please choose an option.'
	end
	write(server, 'filter', filterList)
end

function coin()
	local result = 'heads ' .. client:getEmoji('717821936163356723').mentionString
	if math.random(0, 1) == 0 then
		result = 'tails ' .. client:getEmoji('717821935924543560').mentionString
	end
	entry[16]['content'] = 'You got... ' .. result
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
		sum = sum + math.random(1, diceType)
	end
	entry[17]['content'] = 'You got... ' .. sum .. ' 🎲'
end

--send the message
function output(i, channel, message, bot)
	local sentID
	if entry[i]['type'] == 'message' then
		sentID = channel:send(entry[i]['content'])
	elseif entry[i]['type'] == 'embed' then
		entry[i]['content']['color'] = discordia.Color.fromRGB(32, 102, 148).value
		sentID = channel:send{embed = entry[i]['content']}
	end
	if i == 11 and message then
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
	if entry[11]['code'] > 0 then
		for i = 1,entry[11]['code'],1 do
			sentID:addReaction(emotes[i])
		end
	end
end

--run
client:run('Bot ' .. json.decode(io.open('config.json', 'r'):read('*a'))['Token'])
