import Foundation
import TelegramBotSDK

// Read the token from a the file
let token = readToken(from: "BOT_TOKEN")
let bot = TelegramBot(token: token)
let router = Router(bot: bot)

router["greet"] = { context in
    guard let from = context.message?.from else { return false }
    context.respondAsync("Hello, \(from.firstName)!")
    return true
}

/// Queries the status of one of the AMP servers
router["status"] = StatusCommand.runCommand


while let update = bot.nextUpdateSync() {
    try router.process(update: update)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
