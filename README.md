# Cosmog
A general-purpose Discord bot with a variety of useful commands.

Made in Lua with [Discordia](https://github.com/SinisterRectus/Discordia/wiki).<br>
June 2020.

## Features
Command | Function
------- | --------
coin | Flips a coin.
dice | Rolls dice.
eightball | Ask a question!
emote | Gets an emote as an image.
filter | Manages the list of filtered words.
help | Gets a list of commands.
hug | Hug someone!
info | Gets Cosmog's information.
invite | Gets Cosmog's invite link.
kiss | Kiss someone!
lick | Lick someone!
pat | Pat someone!
pick | Picks between multiple options.
ping | Checks to see if Cosmog is online.
poll | Creates a poll.
prefix | Changes Cosmog's prefix.
purge | Bulk deletes messages.
random | Gets a random number between two integers.
remind | Sets a reminder.
say | Says something.
server | Gets information about the server.
ship | Rates your OTP.
slap | Slap someone!
snuggle | Cuddle someone!
user | Gets information about a user.
welcome | Configures a welcome message.

## Hosting
1. Install [Luvit](https://luvit.io/install.html).
    1. On supported platforms, run `curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh`.
    1. Add Luvit to your PATH with `sudo mv luvi lit luvit /usr/local/bin`.
1. Install [Discordia](https://github.com/SinisterRectus/Discordia/wiki/Installing-Discordia).
    1. Run `lit install SinisterRectus/discordia`.
1. Create a new [Discord application](https://discord.com/developers/applications).
    1. Navigate to the [Discord application](https://discord.com/developers/applications) page.
    1. Click "New Application."
    1. Enter a name.
    1. Navigate to the "Bot" tab.
    1. Click "Add Bot" and confirm that you want to do so.
    1. Navigate to the "OAuth2" tab.
    1. Under "Scopes," click "bot."
    1. Under "Bot Permissions," click "Administrator."
    1. Use the provided link to invite the bot.
    1. Navigate to the "General Information" tab.
    1. Copy the "Client Secret."
1. Download and configure [Cosmog](https://github.com/kattakatkatherine/cosmog.git).
    1. Download Cosmog with `git clone https://github.com/kattakatkatherine/cosmog.git`.
    1. Navigate to the folder with `cd cosmog`.
    1. Open the configuration file with `nano config.json`.
    1. Paste the "Client Secret" into the "Token" slot.
    1. Exit Nano with `CTRL+X`; `y`; `ENTER`.
1. Run the bot with `luvit bot.lua`.
