//
//  ListAllCommand.swift
//  
//
//  Created by Jonas Frey on 01.05.21.
//

import Foundation
import Telegrammer
import Shared

struct ListAllCommand: Command {
    
    let name = "List All"
    let commands = ["/listall"]
    let syntax = "/listall"
    let description = "Lists all entries from all chats"
    let permission = BotPermission.admin
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        guard let type = update.message?.chat.type, type == .private else {
            try bot.sendMessage("Due to privacy reasons, this command can only be executed in a private chat.", to: chatID)
            return
        }
        // List all entries grouped by chat
        let entries = try ConfigParser.getConfig()
        // Obtain all chat IDs (without duplicates)
        let groups = Array(Set(entries.map({ $0.chatID })))
        var list = "*Monitored Websites:*\n"
        for chatID in groups {
            // Escape the chat ID because it could have a minus sign in front of it
            list += "*\(String(chatID).escaped()):*\n"
            for entry in entries.filter({ $0.chatID == chatID }) {
                // For each entry in this group
                list += "- \(entry.name): \(entry.url)".escaped()
                if entry.area.width != 0 && entry.area.height != 0 {
                    list += " (\(entry.area.width)x\(entry.area.height)+\(entry.area.x)+\(entry.area.y))".escaped()
                }
                list += "\n"
            }
            // Extra empty line between groups
            list += "\n"
        }
        while list.hasSuffix("\n") {
            list.removeLast()
        }
        // In case the file was empty
        if entries.isEmpty {
            list += "\n_None_"
        }
        try bot.sendMessage(list, to: chatID, parseMode: .markdownV2)
    }
    
}
