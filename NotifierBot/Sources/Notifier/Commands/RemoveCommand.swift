//
//  RemoveCommand.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation
import Telegrammer

struct RemoveCommand: Command {
    
    let name = "Remove"
    let commands = ["/remove"]
    let syntax = "/remove <name>"
    let description = "Removes an entry from the list"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 1 else {
            try showUsage(chatID)
            return
        }
        
        let name = args[0]
        var config = try ConfigParser.getConfig()
        // Use .firstIndex instead of .removeAll(where:) to check if there even was an entry that got removed
        let index = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard index != nil else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        // Get the real name with the correct capitalization
        let realName = config[index!].name
        config.remove(at: index!)
        try ConfigParser.saveConfig(config)
        try bot.sendMessage("Successfully removed '\(realName)'", to: chatID)
    }
    
}
