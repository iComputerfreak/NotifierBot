import Foundation
import Telegrammer

// An ordered list of all commands to register
// The order defines the order of commands in the /help list
let allCommands: [Command] = [
    HelpCommand(), ListCommand(), ListURLsCommand(), InfoCommand(), MyIDCommand(),
    AddCommand(), RemoveCommand(), UpdateCommand(), SetDelayCommand(), SetCaptureElementCommand(), SetClickElementCommand(), SetWaitElementCommand(), FetchCommand(), FetchURLCommand(), DiffCommand(), MuteCommand(), UnmuteCommand(),
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
