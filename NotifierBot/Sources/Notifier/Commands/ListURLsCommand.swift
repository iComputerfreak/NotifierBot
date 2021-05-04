//
//  ListURLsCommand.swift
//  
//
//  Created by Jonas Frey on 01.05.21.
//

import Foundation
import Telegrammer

struct ListURLsCommand: Command {
    
    let name = "List URLs"
    let commands = ["/listurls"]
    let syntax = "/listurls"
    let description = "Lists all entries including their websites"
    let permission = BotPermission.user
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let entries = try ConfigParser.getConfig().filter({ $0.chatID == chatID })
        let list = JFUtils.entryList(entries, listArea: false, listURLs: true)
        try bot.sendMessage(list, to: chatID, parseMode: .markdownV2)
    }
    
}
