//
//  SetPermissionsCommand.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation
import Telegrammer

struct SetPermissionsCommand: Command {
    
    let name = "Set Permissions"
    let commands = ["/setpermissions"]
    let syntax = "/setpermissions <level> [id]"
    let description = "Sets the permission level of the author of the message, replied to or the user id provided"
    let permission = BotPermission.admin
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 1 || args.count == 2 else {
            try showUsage(chatID)
            return
        }
        let userID: Int64!
        let username: String!
        if args.count == 1 {
            // Use the reply message
            guard let user = update.message?.replyToMessage?.from, user.username != botUser.username else {
                try bot.sendMessage("Error: Please respond to a message of a user.", to: chatID)
                return
            }
            userID = user.id
            username = user.username ?? "<Unknown>"
        } else {
            // Use the ID provided
            guard let id = Int64(args[1].trimmingCharacters(in: .whitespaces)) else {
                try bot.sendMessage("Error: Please provide the user ID as an integer.", to: chatID)
                return
            }
            userID = id
            username = "\(id)"
        }
        guard let level = BotPermission(rawValue: args[0].trimmingCharacters(in: .whitespaces)) else {
            try bot.sendMessage("Error: Please specify a valid bot permission: \(BotPermission.allCases.map({ $0.rawValue }).joined(separator: ", "))", to: chatID)
            return
        }
        try ConfigParser.shared.setPermissionGroup(user: userID, level: level)
        try bot.sendMessage("Successfully set the permission level of \(username!.escaped()) to *\(level.rawValue)*.", to: chatID, parseMode: .markdownV2)
    }
}
