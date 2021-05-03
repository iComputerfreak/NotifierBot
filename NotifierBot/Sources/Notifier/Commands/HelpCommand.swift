//
//  HelpCommand.swift
//  
//
//  Created by Jonas Frey on 30.04.21.
//

import Foundation
import Telegrammer

/// Prints all commands including their usage and permission levels
struct HelpCommand: Command {
        
    let name: String = "Help"
    let commands: [String] = ["/help", "/start"]
    let permission = BotPermission.user
    let syntax = "/help"
    let description = "Lists all commands and their descriptions"
    
    /// Prints all commands including their usage and permission levels
    /// - Parameter update: The update instance calling this command
    /// - Parameter context: The bot context
    /// - Throws: `BotError.noPermissions`, if the user does not have the required permission level
    /// - Returns: Whether other commands should be matched
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        var usage = ""
        for permission in BotPermission.allCases {
            let commands = allCommands.filter({ $0.permission == permission })
            // Print the commands for this group
            usage += "*\(permission.rawValue.capitalized)*\n"
            for command in commands {
                usage += "\(command.syntax)\n\(command.description)\n"
            }
            // Extra space between permission groups
            usage += "\n"
        }
        if usage.hasSuffix("\n") {
            usage.removeLast()
        }
        try bot.sendMessage(usage, to: chatID)
    }
    
}
