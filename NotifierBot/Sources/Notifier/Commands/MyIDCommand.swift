//
//  MyIDCommand.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation
import Telegrammer

struct MyIDCommand: Command {
    
    let name = "My ID"
    let commands = ["/myid"]
    let syntax = "/myid"
    let description = "Returns your User ID"
    let permission = BotPermission.user
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        guard let user = update.message?.from else {
            try bot.sendMessage("Unable to determine user.", to: chatID)
            return
        }
        try bot.sendMessage("The user ID of \(user.username?.escaped() ?? "<Unknown>") is `\(user.id)`", to: chatID, parseMode: .markdownV2)
    }
}
