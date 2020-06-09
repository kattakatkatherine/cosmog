# Cosmog
A general-purpose Discord bot with a variety of useful commands.

Made in Lua with [Discordia](https://github.com/SinisterRectus/Discordia/wiki).<br>
Summer 2020.

## Features
Command | Function
------- | --------
ping | Checks to see if Cosmog is online.
info | Gets Cosmog's information.
help | Gets a list of commands.
invite | Grabs Cosmog's invite link.
say | Says something.
avatar | Gets a user's profile picture.
emote | Gets an emote as an image.
random | Gets a random number between two integers.
pick | Picks between multiple options.
server | Gets information about the server.
poll | Creates a poll.
prefix | Changes Cosmog's prefix.
welcome | Configures a welcome message.
remind | Sets a reminder.
filter | Manages the list of filtered words.
coin | Flips a coin.
dice | Rolls dice.

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
