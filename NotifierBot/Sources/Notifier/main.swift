import Foundation
import Telegrammer

// Save the directory, the program is executed in for the shell scripts later
let mainDirectory = Bundle.main.executablePath?
    // Remove the filename, only use the directory
    .split(separator: "/", omittingEmptySubsequences: false).dropLast().map(String.init).joined(separator: "/")
print("Installation Directory: \(mainDirectory ?? "nil")")

// If no install directory could be constructed:
guard mainDirectory != nil else {
        print("ERROR: Unable to read the installation directory!")
        exit(1)
}

/* ****************** */
/* START BOT SETTINGS */
/* ****************** */

// The file containing the permission levels of the users
let kPermissionsFile = "\(mainDirectory!)/permissions.txt"
// The file containing the urls and their settings
let kURLListFile = "\(mainDirectory!)/urlwatcher/urls.list"
// The url_watcher.sh script that actually performs the monitoring
let kUrlwatchTool = "\(mainDirectory!)/urlwatcher/urlwatcher"
// The python screenshot script that takes the screenshot
let kScreenshotScript = "\(mainDirectory!)/tools/screenshot.sh"
// The telegram.sh script from here: https://github.com/fabianonline/telegram.sh
let kTelegramScript = "\(mainDirectory!)/tools/telegram.sh"

// You probably don't need to change these:
// The python3 binary
let kPythonPath = "/usr/bin/python3"
// The convert binary from the imagemagick package
let kConvertPath = "/usr/bin/convert"

// The file containing the detailed NCC information, produced by the urlwatcher.sh script
let nccFile = "ncc"
// The diff image
let diffFile = "diff.png"

/* END BOT SETTINGS */

// An ordered list of all commands to register
// The order defines the order of commands in the /help list
let allCommands: [Command] = [
    HelpCommand(), ListCommand(), ListURLsCommand(), InfoCommand(), MyIDCommand(),
    AddCommand(), RemoveCommand(), UpdateCommand(), SetDelayCommand(), SetCaptureElementCommand(), SetClickElementCommand(), SetWaitElementCommand(), FetchCommand(), FetchURLCommand(), DiffCommand(),
    ListAllCommand(), CheckCommand(), GetPermissionsCommand(), SetPermissionsCommand()
]

var token: String!
let bot: Bot!
let botUser: User!

do {

    if let t = try? String(contentsOfFile: "BOT_TOKEN").components(separatedBy: .newlines).first {
        // Read the token from a the file
        print("Reading token from file.")
        token = t
    } else if let t = Enviroment.get("TELEGRAM_BOT_TOKEN") {
        // Read the token from the environment, if it exists
        print("Reading token from environment.")
        token = t
    } else {
        print("Error: Unable to read token.")
        exit(1)
    }
    bot = try Bot(token: token)
    botUser = try bot.getMe().wait()
    guard let _ = botUser.username else {
        print("Unable to retrieve bot username")
        exit(1)
    }

    // Create a dispatcher and start polling
    let dispatcher = Dispatcher(bot: bot)
    for command in allCommands {
        dispatcher.add(command: command)
    }
    
    _ = try Updater(bot: bot, dispatcher: dispatcher).startLongpolling().wait()
} catch let error {
    print(error)
    exit(1)
}
