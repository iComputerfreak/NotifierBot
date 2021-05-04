//
//  Command.swift
//  
//
//  Created by Jonas Frey on 30.04.21.
//

import Foundation
import Telegrammer

protocol Command {
    
    var name: String { get }
    var commands: [String] { get }
    var permission: BotPermission { get }
    /// Syntax of the command, used when showing the the usage. Contents of this string will be escaped so they can be used in markdownV2 format.
    var syntax: String { get }
    var usage: String { get }
    var description: String { get }
    
    var handler: Handler { get }
    
    func run(update: Update, context: BotContext?) throws
    
    func showUsage(_ chatID: Int64) throws
}

extension Command {
    
    var usage: String {
        return "Usage: " + syntax
    }
    
    var handler: Handler {
        // Add 'Command@Botname' syntax
        let commands = self.commands + self.commands.map({ "\($0)@\(botUser.username!)" })
        return CommandHandler(name: name, commands: commands, callback: { (update, context) in
            do {
                // Check if the sender is a user
                guard let userID = update.message?.from?.id else {
                    throw JFBotError.noUserID
                }
                // Check if the user has the required permissions
                guard PermissionHandler.shared.hasPermission(userID: userID, permission: self.permission) else {
                    throw JFBotError.noPermissions(self)
                }
                // Run the command
                try self.run(update: update, context: context)
            } catch let error as JFBotError {
                JFErrorHandler.shared.handle(error, update: update)
            }
        })
    }
    
    func showUsage(_ chatID: Int64) throws {
        try bot.sendMessage(usage, to: chatID)
    }
}
