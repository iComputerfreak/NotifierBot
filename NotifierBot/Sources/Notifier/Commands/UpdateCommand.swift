//
//  UpdateCommand.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation
import Telegrammer

struct UpdateCommand: Command {
    
    let name = "Update"
    let commands = ["/update"]
    let syntax = "/update <name> <x> <y> <width> <height>"
    let description = "Updates the screenshot area of an entry"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 5 else {
            try showUsage(chatID)
            return
        }
        let name = args[0]
        let x = Int(args[1])
        let y = Int(args[2])
        let width = Int(args[3])
        let height = Int(args[4])
        
        // Check if parsing to integer worked
        guard x != nil && y != nil && width != nil && height != nil else {
            try bot.sendMessage("Please enter a valid Offset and Size.", to: chatID)
            return
        }
                
        var config = try ConfigParser.getConfig()
        // Use the index, because we want to modify it (URLEntry is a struct, so pointers wouldn't work)
        let entryIndex = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entryIndex != nil else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        var entry = config[entryIndex!]
        entry.area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        config[entryIndex!] = entry
        try ConfigParser.saveConfig(config)
        try bot.sendMessage("Successfully updated \(entry.name)", to: chatID)
    }
}
