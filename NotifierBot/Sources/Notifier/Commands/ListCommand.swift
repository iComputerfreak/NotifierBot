//
//  ListCommand.swift
//  
//
//  Created by Jonas Frey on 01.05.21.
//

import Foundation
import Telegrammer

struct ListCommand: Command {
    
    let name = "List"
    let commands = ["/list"]
    let syntax = "/list"
    let description = "Lists all entries including their areas"
    let permission = BotPermission.user
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let entries = try ConfigParser.getConfig().filter({ $0.chatID == chatID })
        let list = JFUtils.entryList(entries)
        try bot.sendMessage(list, to: chatID, parseMode: .markdownV2)
    }
    
}
