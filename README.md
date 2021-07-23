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
`/info <name>`  
Shows more information about a specific entry  
`/myid`  
Returns your User ID  
`/add <name> <URL> [x y width height]`  
Adds a new website with an optional screenshot area to the list  
`/remove <name>`  
Removes an entry from the list  
`/update <name> <x> <y> <width> <height>`  
Updates the screenshot area of an entry  
`/setdelay <name> <delay>`  
Specifies a delay in seconds to wait after the website has been loaded  
`/setcaptureelement <name> [html element]`  
Specifies which HTML element to capture  
`/setclickelement <name> [html element]`  
Specifies which HTML element to click before taking the screenshot  
`/setwaitelement <name> [html element]`  
Specifies which HTML element to wait for before taking the screenshot  
`/fetch <name>`  
Takes a screenshot with the stored settings and sends it into this chat  
`/fetchurl <URL> [x y width height]`  
Takes a screenshot of the given website and settings and sends it into this chat  
`/diff <name>`  
Shows a picture highlighting the differences of the last website change, including extended information about the normalized cross correlation  
`/listall`  
Lists all entries from all chats  
`/check`  
Performs a manual check if any monitored website changed  
`/getpermissions [id]`  
Returns the permission level of the author of the message, replied to or the user id provided  
`/setpermissions <level> [id]`  
Sets the permission level of the author of the message, replied to or the user id provided  

## Installation (Linux)

### Prerequisites
For the bot to work, you first need the following things:
- ImageMagick (for cropping the screenshot using the `convert` tool and comparing the screenshots using `compare`)
- [`capture-website-cli`](https://github.com/sindresorhus/capture-website-cli) to take the screenshots
  

1. Clone the repository: `git clone https://github.com/iComputerfreak/NotifierBot`
2. Change into the telegram bot source code directory: `cd NotifierBot/NotifierBot`
3. Build the code: `swift build -c release`
4. Copy the executable into the main directory: `cp .build/release/Notifier ..`
5. Switch to the parent directory: `cd ..`
6. Download the [telegram.sh script](https://github.com/fabianonline/telegram.sh): `wget -O tools/telegram.sh https://raw.githubusercontent.com/fabianonline/telegram.sh/master/telegram`
7. Make the telegram script executable: `chmod +x tools/telegram.sh`
8. Repeat steps 2 - 5 for the urlwatcher script:
```swift
cd urlwatcher
swift build -c release
cp .build/release/urlwatcher .
cd ..
```

If you completed all the steps above, your install directory should look like this:
```bash
$ tree -L 2
.
├── LICENSE
├── Notifier
├── NotifierBot
│   ├── Package.resolved
│   ├── Package.swift
│   ├── Sources
│   └── Tests
├── README.md
├── tools
│   ├── screenshot.sh
│   └── telegram.sh
└── urlwatcher
    ├── Package.swift
    ├── Sources
    ├── urlwatcher
    └── urlwatcher.sh.old
```

### Adding the urlwatch script to crontab
For the urlwatch script to be periodically executed, you have to create a cronjob for it.
1. Edit the crontab file: `crontab -e`
2. Add the following line at the end: `*/30 * * * * /path/to/your/install/directory/urlwatcher/urlwatcher`  
This executes the script every 30 minutes. To execute it e.g. every hour, use `0 * * * *` (every time the minute is zero).
3. Save the file

## Setup

### Create the BOT_TOKEN file
For the scripts and the bot to work, you have to put your bot token in a file called BOT_TOKEN in your installation directory.
1. `cd` to your installation directory
2. Create the file: `echo YOUR_BOT_TOKEN > BOT_TOKEN`

### Give yourself admin permissions
1. Start the bot
2. Run the command `/myid` to retrieve your ID
3. Stop the bot
4. Add your ID to the permissions file: `echo "YOUR_ID: admin" > /path/to/your/install/directory/permissions.txt`
5. Start the bot again and make sure, it worked by checking your permissions with the bot: `/getpermissions YOUR_ID`
6. If the bot returned your permission level as **admin**, everything worked and you now have admin permissions

**Note**: Modifying the permissions file requires a restart of the bot, but using `/setpermissions <level> <userid>` does not.

### (Optional) Create a systemd service for the bot
1. Create the unit file: `sudo nano /etc/systemd/system/notifier.service`
2. Paste the following content (replace `YOUR_USER_ACCOUNT` with your linux user account name):
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
