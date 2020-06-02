local discordia = require('discordia')
local json = require ('json')
local client = discordia.Client()

--[[
	Cosmog
	by Katherine Gearhart
	Summer 2020

	Created with Discordia
	https://github.com/SinisterRectus/Discordia/wiki
]]

client:on('ready', function()
	print('Logged in as Cosmog')
	client:setGame("$help")
end)

entry = {
	{command = 'ping', content = 'Pong!', type = 'message', alias = 'pong', description = 'Checks to see if Cosmog is online.', usage = 'ping'},
	{command = 'info', type = 'embed', description = 'Gets Cosmog\'s information.', usage = 'info'},
	{command = 'help', type = 'embed', description = 'Gets a list of commands.', usage = 'help (command)'},
	{command = 'invite', content = 'https://discord.com/api/oauth2/authorize?client_id=711547275410800701&permissions=8&scope=bot', type = 'message', description = 'Grabs Cosmog\'s invite link.', usage = 'invite'},
	{command = 'say', type = 'message', alias = 'echo', description = 'Says something.', usage = 'say [text]'},
	{command = 'avatar', type = 'embed', alias = 'pfp', description = 'Gets a user\'s profile picture.', usage = 'avatar (mention)'},
	{command = 'emote', alias = 'emoji', description = 'Gets an emote as an image.', usage = 'emote [emote]'},
	{command = 'random', type = 'message', alias = 'rand', description = 'Gets a random number between two integers.', usage = 'random [integer], [integer]'},
	{command = 'pick', type = 'message', alias = 'choose', description = 'Picks between multiple options.', usage = 'pick [option] or [option]'},
	{command = 'server', alias = 'guild', description = 'Gets information about the server.', usage = 'server [option]', note = 'Options include \"icon,\" \"banner,\" \"splash,\" \"owner,\" \"members,\" and \"name.\"'},
	{command = 'poll', alias = 'vote', description = 'Creates a poll.', usage = 'poll [{question}] [{option}] [{option}]'},
	{command = 'prefix', type = 'message', description = 'Changes the bot\'s prefix.', usage = 'prefix [option]', perms = 8},
	{command = 'welcome', type = 'message', description = 'Configures a welcome message.', usage = 'welcome [channel] [message]', note = '\"$server$\" and \"$user$\" are replaced with the server name and the new user, respectively.', perms = 8},
	{command = 'remind', type = 'message', alias = 'reminder', description = 'Sends a reminder.', usage = 'remind [duration] [message]', note = 'Duration is in minutes.'},
	{command = 'filter', description = 'Manages the list of filtered words.', usage = 'filter [option] (word)', note = 'Options include \"add,\" \"remove,\" \"list,\" and \"clear.\"', perms = 8},
	[0] = {} --left blank
}


client:on('messageCreate', function(message)

	--deletes words with filtered terms
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

	--check prefix
	currentPrefix = read(message.guild.id, 'prefix', '$')

	--determine command
	for i = 1, table.maxn(entry), 1 do
		if message.content:sub(1, #currentPrefix + #entry[i]['command']) == currentPrefix .. entry[i]['command'] or entry[i]['alias'] and message.content:sub(1, #currentPrefix + #entry[i]['alias']) == currentPrefix .. entry[i]['alias'] then

			--print command used
			print(entry[i]['command'])

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

			--dynamic commands
			if i == 2 then
				info(tostring(#client.guilds), client:getUser(client.user.id):getAvatarURL() .. '?size=1024')
			elseif i == 3 then
				help(cleanContent)
			elseif i == 5 then
				say(message.author.bot, message.content, message)
			elseif i == 6 then
				avatar(message.mentionedUsers.first, message.author)
			elseif i == 7 then
				emote(message.mentionedEmojis.first, message.content)
			elseif i == 8 then
				random(cleanContent)
			elseif i == 9 then
				pick(message.content)
			elseif i == 10 then
				server(cleanContent, message.guild)
			elseif i == 11 then
				poll(message.content, message)
			elseif i == 12 then
				prefix(message.content, message.guild.id, message.guild:getMember(client.user.id))
			elseif i == 13 then
				welcome(message.mentionedChannels.first, message.content, message.guild.id)
			elseif i == 14 then
				remind(message.content, message.author.mentionString, message)
			elseif i == 15 then
				filter(message.guild.id, message.content)
			end

			--send message
			output(i, message.channel, message)
			return
		end
	end
end)

--when someone joins...
client:on('memberJoin', function(member)
	welcomeChannel = read(member.guild.id, 'welcomeChannel', nil)
	welcomeMessage = read(member.guild.id, 'welcomeMessage', nil)
	if welcomeChannel then
		entry[0]['type'] = 'message'
		entry[0]['content'] = welcomeMessage:gsub('%$server%$', member.guild.name):gsub('%$user%$', member.user.mentionString)
		output(0, client:getChannel(welcomeChannel), nil)
	end
end)

--restores nickname upon rejoining a server
client:on('guildCreate', function(guild)
	nickManage(guild:getMember(client.user.id))
end)

function info(servers, pfp)
	entry[2]['content'] = {
		title = 'Cosmog',
		thumbnail = {url = pfp},
		description = 'A general-purpose bot with a variety of useful commands.\nCurrently in ' .. servers .. ' servers.',
		footer = {text = 'Created by kat#8931 <3'}
	}
end

function help(content)
	if content:find(' ') then
		local content = content:sub(content:find(' ') + 1)
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
	entry[3]['content'] = {title = 'Help', fields = {}}
	for i = 1, table.maxn(entry), 1 do
		entry[3]['content']['fields'][i] = {name = entry[i]['command'], value = entry[i]['description'], inline = false}
	end
end

function say(bot, content, message)
	if not bot then
		if content:find(' ') then
			entry[5]['content'] = content:sub(content:find(' ') + 1)
			message:delete()
		else
			entry[5]['content'] = 'What should I say?'
		end
	else
		entry[5]['content'] = ''
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
		if content:find(' ') then
			entry[7]['content'] = 'I can only grab custom emotes that are on this server.'
		else
			entry[7]['content'] = 'Which emote should I grab?'
		end
	end
end

function random(content)
	if content:find(', ') and not content:sub(content:find(' ') + 1):match('[^0-9, %-]') then
		local secondNumber
		secondNumber = content:sub(content:find(', ') + 2)
		if(secondNumber:find('[, ]')) then
			secondNumber = secondNumber:sub(1, secondNumber:find(secondNumber:match('[^0-9]')) - 1)
		end
		math.randomseed(os.time())
		entry[8]['content'] = math.random(content:sub(content:find(' ') + 1, content:find(', ') - 1), secondNumber)
	else
		entry[8]['content'] = 'What range would you like to use?'
	end
end

function pick(content)
	local tcontent = content:sub(content:find(' ') + 1)
	local toptions = {}
	while tcontent:find(' or ') do
		toptions[table.maxn(toptions) + 1] = tcontent:sub(1, tcontent:find(' or '))
		tcontent = tcontent:sub(tcontent:find(' or ') + 4)
	end
	toptions[table.maxn(toptions) + 1] = tcontent
	entry[9]['content'] = 'Make sure to separate the options with \"or.\"'
	if table.maxn(toptions) ~= 0 then
		math.randomseed(os.time())
		entry[9]['content'] = 'I pick... ' .. toptions[math.random(1, table.maxn(toptions))]
	end
end

function server(content, server)
	entry[10]['type'] = 'message'
	if content:find(' ') then

		tentry = {
			{option = 'icon', type = 'image', content = server.iconURL, fail = 'an icon'},
			{option = 'banner', type = 'image', content = server.bannerURL, fail = 'a banner'},
			{option = 'splash', type = 'image', content = server.splashURL, fail = 'a splash image'},
			{option = 'owner', type = 'message', content = server.owner.user.tag .. ' owns this server.'},
			{option = 'members', type = 'message', content = tostring(server.totalMemberCount) .. ' users are in this server.'},
			{option = 'name', type = 'message', content = 'This server is called ' .. server.name .. '.'},
		}

		for i = 1, table.maxn(tentry), 1 do
			if content:sub(content:find(' ') + 1) == tentry[i]['option'] then
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
	entry[11]['content'] = 'Please surround the question with curly brackets.'
	if content:find('{') and content:find('}') and content:find('{') < content:find('}') then
		local tquestion = content:sub(content:find('{') + 1, content:find('}') - 1)
		local tcontent = content:sub(content:find('}') + 1)
		local i = 0
		local toptions = ''
		emotes = {'🇦','🇧','🇨','🇩','🇪','🇫','🇬','🇭','🇮','🇯','🇰','🇱','🇲','🇳','🇴','🇵','🇶','🇷','🇸','🇹'}

		while tcontent:find('{') and tcontent:find('}') and i <= 20 do
			i = i + 1
			toptions = toptions .. '\n\n'..emotes[i] .. ' ' .. tcontent:sub(tcontent:find('{') + 1, tcontent:find('}') - 1)
			tcontent = tcontent:sub(tcontent:find('}') + 1)
			entry[11]['code'] = i
		end

		message:delete()
		entry[11]['type'] = 'embed'
		entry[11]['content'] = {title = tquestion, description = toptions}
	end
end

function prefix(content, server, bot)
	if content:find(' ') then
		currentPrefix = content:sub(content:find(' ') + 1)
		write(server, 'prefix', currentPrefix)
		entry[12]['content'] = 'Changed this server\'s prefix to ' .. currentPrefix
		nickManage(bot)
	else
		entry[12]['content'] = 'What would you like this server\'s prefix to be?'
	end
end

function welcome(channel, content, server)
	if channel then
		if #content:sub(content:find(channel.mentionString) + #channel.mentionString) > 0 then
			welcomeChannel = channel.id
			welcomeMessage = content:sub(content:find(channel.mentionString) + #channel.mentionString)
			write(server, 'welcomeChannel', welcomeChannel)
			write(server, 'welcomeMessage', welcomeMessage)
			entry[13]['content'] = 'The welcome message has been set.'
		else
			entry[13]['content'] = 'What message would you like me to send?'
		end
	else
		entry[13]['content'] = 'What channel would you like me to send the message in?'
	end
end

function remind(content, mention, message)
	if content:find(' ') then
		local timer = require('timer')
		local duration = content:sub(content:find(' ') + 1, content:sub(content:find(' ') + 1):find('[^.0-9]') + content:find(' ') - 1)
		if duration:match('[%.0-9]+') == duration then
			entry[14]['content'] = 'Your reminder has been set!'
			output(14, message.channel, message, message.guild:getMember(client.user.id))
			--send confirmation, then wait
			timer.sleep(duration * 60000)
			entry[14]['content'] = '**Reminder** ' .. mention .. ':' .. content:sub(content:find(duration) + #duration)
		else
			entry[14]['content'] = 'When would you like me to remind you?'
		end
	else
		entry[14]['content'] = 'When would you like me to remind you?'
	end
end

function filter(server, content, channel)
	filterList = read(server, 'filter', false)
	entry[15]['type'] = 'message'
	if content:find('$filter add ') then
		filterList[table.maxn(filterList) + 1] = content:sub(content:find('$filter add ') + #'$filter add '):lower()
		entry[15]['content'] = 'The above word has been added to the filter list.'
	elseif content:find('$filter remove ') then
		local removeWord = content:sub(content:find('$filter remove ') + #'$filter remove '):lower()
		for i = 1, table.maxn(filterList), 1 do
			if removeWord == filterList[i] then
				table.remove(filterList, i)
				entry[15]['content'] = '\"' .. removeWord:gsub('^%l', string.upper) .. '\" has been removed from the filter list.'
			elseif i == table.maxn(filterList) then
				entry[15]['content'] = 'It appears that \"' .. removeWord .. '\" is not on the filter list.'
			end
		end
	elseif content:find('$filter list') then
		entry[15]['content'] = {title = 'Filtered Words', description = ''}
		entry[15]['type'] = 'embed'
		for i = 1, table.maxn(filterList), 1 do
			entry[15]['content']['description'] = entry[15]['content']['description'] .. '\n' .. filterList[i]
		end
	elseif content:find('$filter clear') then
		filterList = {}
		entry[15]['content'] = 'The filter list has been cleared.'
	else
		entry[15]['content'] = 'Please choose an option.'
	end
	write(server, 'filter', filterList)
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
	local file = io.open('config.json', 'r')
	local search = file:read('*a')
	file:close()
	local decoded = json.decode(search)

	if not decoded[server] then
		decoded[server] = {}
	end

	decoded[server][option] = content
	local encoded = json.encode(decoded)
	local file = io.open('config.json', 'w+')
	file:write(encoded)
	file:close()
end

--reads from config file
function read(server, option, default)
	local file = io.open('config.json', 'r')
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
	if currentPrefix ~= '$' then
		nickname = 'Cosmog [' .. currentPrefix .. ']'
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

--token stored in outside file
client:run('Bot ' .. io.open('../token.txt'):read())
