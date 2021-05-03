//
//  GetPermissionsCommand.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation
import Telegrammer

struct GetPermissionsCommand: Command {
    
    let name = "Get Permissions"
    let commands = ["/getpermissions"]
    let syntax = "/getpermissions \\[id]"
    let description = "Returns the permission level of the author of the message, replied to or the user id provided"
    let permission = BotPermission.admin
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count <= 1 else {
            try showUsage(chatID)
            return
        }
        
        // TODO: Check if it works with mentions
        let _ = update.message?.entities
        
        let userID: Int64!
        let username: String!
        if args.count == 0 {
            // Use the reply message
            guard let user = update.message?.replyToMessage?.from, !user.isBot else {
                try bot.sendMessage("Error: Please respond to a message of a user.", to: chatID)
                return
            }
            userID = user.id
            username = user.username ?? "<Unknown>"
        } else {
            // Use the ID provided
            guard let id = Int64(args[0].trimmingCharacters(in: .whitespaces)) else {
                try bot.sendMessage("Error: Please provide the user ID as an integer.", to: chatID)
                return
            }
            userID = id
            username = "\(id)"
        }
        let level = ConfigParser.shared.permissionGroup(user: userID)
        try bot.sendMessage("The permission level of \(username!) is *\(level.rawValue)*.", to: chatID)
    }
}
