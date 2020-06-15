import Foundation
import TelegramBotSDK

enum BotError: Error {
    // Contains the line that is malformed
    case malformedLineSegments(String)
    // Contains the line with the malformed integers
    case malformedIntegers(String)
    case noChatID
    // Contains the command that has been tried to execute
    case noPermissions(JFCommand)
    // Contains the line with the malformed permission
    case malformedPermissions(String)
}

// Read the token from a the file
let token = readToken(from: "BOT_TOKEN")
let bot = TelegramBot(token: token)
let configParser = ConfigParser()

// Disable Notifications by default
bot.defaultParameters["sendMessage"] = ["disable_notification": true, "disable_web_page_preview": true]

// Register and handle Commands
let mainController = MainController()
let permissionController = PermissionController()

while let update = bot.nextUpdateSync() {
    update.prettyPrint()
    do {
        // Process the update
        try permissionController.process(update: update)
        // If the user would have insufficient permissions, the above line would have thrown an error
        // Otherwise, execute the main controller
        try mainController.process(update: update)
        
    } catch BotError.malformedLineSegments(let line) {
        if let chatID = update.message?.chat.id {
            bot.sendMessageAsync(chatId: chatID, text: "Config Error: Malformed line. Check the log for additional information.")
        }
        print("Error reading config: Malformed line. Expected name,x,y,width,height,chatID,url:\n    \(line)")
    } catch BotError.malformedIntegers(let line) {
        if let chatID = update.message?.chat.id {
            bot.sendMessageAsync(chatId: chatID, text: "Config Error: Malformed line. Check the log for additional information.")
        }
        print("Error reading config: Malformed line. Expected x, y, width and height as Integers.\n    \(line)")
    } catch BotError.noChatID {
        if let chatID = update.message?.chat.id {
            bot.sendMessageAsync(chatId: chatID, text: "Error: This chat has no chat ID!")
        }
        print("Error: No chat ID associated with this chat")
    } catch BotError.noPermissions(let command) {
        if let chatID = update.message?.chat.id {
            bot.sendMessageAsync(chatId: chatID, text: "This action requires the permission level *\(command.permission.rawValue)*.", parseMode: "markdown")
        }
        var name = "\(update.message?.from?.username ?? "Unknown User")"
        if let firstName = update.message?.from?.firstName, let lastName = update.message?.from?.lastName {
            name += " (\(firstName) \(lastName))"
        }
        print("\(name) tried to perform the command \(command), but failed due to insufficient permissions.")
    } catch let e {
        if let chatID = update.message?.chat.id {
            bot.sendMessageAsync(chatId: chatID, text: "An unknown error occured. Please check the log.")
        }
        print(e)
    }
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
