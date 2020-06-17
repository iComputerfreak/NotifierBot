# Notifier Telegram Bot

This bot monitors websites and notifies you via Telegram, when they visually change.

The bot supports the following commands:
`/help`
Lists all commands and their descriptions
`/start`
Lists all commands and their descriptions
`/list`
Lists all entries including their areas
`/listurls`
Lists all entries including their websites
`/myid`
Returns your User ID
`/add <name> <URL> [x y width height]`
Adds a new website with an optional screenshot area to the list
`/remove <name>`
Removes an entry from the list
`/update <name> <x> <y> <width> <height>`
Updates the screenshot area of an entry
`/fetch <name>`
Takes a screenshot with the stored settings and sends it into this chat
`/fetchurl <URL> [x y width height]`
Takes a screenshot of the given website and settings and sends it into this chat
`/listall`
Lists all entries from all chats
`/check`
Performs a manual check if any monitored website changed
`/getpermissions [id]`
Returns the permission level of the author of the message, replied to or the user id provided
`/setpermissions <level> [id]`
Sets the permission level of the author of the message, replied to or the user id provided

## Installation

### Prerequisites
For the bot to work, you first need the following things:
- ImageMagick (for cropping the screenshot using the `convert` tool and comparing the screenshots using `identify`)
- Selenium for taking the screenshots (install using pip)
- [Geckodriver](https://github.com/mozilla/geckodriver/releases) (installed in one of these directories: `/usr/local/sbin`, `/usr/local/bin`, `/sbin`, `/bin`, `/usr/sbin` or `/usr/bin`)
- Firefox (install using apt-get)

1. Clone the repository: `git clone https://github.com/iComputerfreak/NotifierBot`
2. Change into the source code directory: `cd NotifierBot/Notifier`
3. Build the code: `swift build`
4. On a successful build, you should be displayed the path of the executable (e.g. `[4/4] Linking ./.build/x86_64-unknown-linux/debug/Notifier`)
4. Copy the executable into the main directory: `cp Notifier/.build/x86_64-unknown-linux/debug/Notifier .`
5. Download the [telegram.sh script](https://github.com/fabianonline/telegram.sh): `wget -O tools/telegram.sh https://raw.githubusercontent.com/fabianonline/telegram.sh/master/telegram`
6. Make the shell scripts executable: `chmod +x urlwatcher/urlwatcher.sh tools/telegram.sh`

If you completed all the steps above, your install directory should look like this:
```bash
$ tree -L 2
<TODO>
```

### Adding the urlwatch script to crontab
For the urlwatch script to be periodically executed, you have to create a cronjob for it.
1. Edit the crontab file: `crontab -e`
2. Add the following line at the end: `*/10 * * * * /path/to/your/install/directory/urlwatcher/urlwatcher.sh`
This executes the script every 10 minutes. To execute it e.g. every hour, use `0 * * * *` (every time the minute is zero).
3. Save the file

## Setup

### (Optional) Create a systemd service for the bot
1. Create the unit file: `sudo nano /etc/systemd/system/notifier.service`
2. Paste the following content (replace `YOUR_USER_ACCOUNT` with your user account name):
```
[Unit]
Description=Telegram Notifier Bot
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=YOUR_USER_ACCOUNT
WorkingDirectory=/path/to/your/install/directory/NotifierBot
ExecStart=/path/to/your/install/directory/NotifierBot/Notifier

[Install]
WantedBy=multi-user.target
```
3. Start the service: `sudo service Notifier start`
4. Optional: Enable automatic start on boot: `sudo service Notifier enable`


### Give yourself admin permissions
1. Start the bot
2. Run the command `/myid` to retrieve your ID
3. Stop the bot
4. Add your ID to the permissions file: `echo "YOUR_ID: admin" > /path/to/your/install/directory/urlwatcher/permissions.txt`
5. Start the bot again and make sure, it worked by checking your permissions with the bot: `/getpermissions YOUR_ID`
6. If the bot returned your permission level as **admin**, everything worked and you now have admin permissions

**Note**: Modifying the permissions file requires a restart of the bot, but using `/setpermissions <level> <userid>` does not.
