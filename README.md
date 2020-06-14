# Cosmog
A general-purpose Discord bot with a variety of useful commands.

Made in Lua with [Discordia](https://github.com/SinisterRectus/Discordia/wiki).<br>
Summer 2020.

## Features
Command | Function
------- | --------
coin | Flips a coin.
dice | Rolls dice.
emote | Gets an emote as an image.
filter | Manages the list of filtered words.
help | Gets a list of commands.
info | Gets Cosmog's information.
invite | Grabs Cosmog's invite link.
pick | Picks between multiple options.
ping | Checks to see if Cosmog is online.
poll | Creates a poll.
prefix | Changes Cosmog's prefix.
purge | Bulk deletes messages.
random | Gets a random number between two integers.
remind | Sets a reminder.
say | Says something.
server | Gets information about the server.
user | Gets information about a user.
welcome | Configures a welcome message.

## Hosting
1. Install [Luvit](https://luvit.io/install.html).
1. Install [Discordia](https://github.com/SinisterRectus/Discordia/wiki/Installing-Discordia).
1. Create a new [Discord application](https://discord.com/developers/applications).
    1. Navigate to the Bot tab.
    1. Configure the application.
    1. Create an invitation link and use it to invite the bot.
    1. Copy the bot token.
1. Download [Cosmog](https://github.com/katherine-gearhart/cosmog.git).
    1. Navigate to `config.json`.
    1. Paste the bot token into the appropriate slot.
    1. Configure the other options as you wish.
1. Run the bot with `luvit bot.lua`.
