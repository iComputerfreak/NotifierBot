//
//  MuteCommand.swift
//  
//
//  Created by Jonas Frey on 03.12.21.
//

import Foundation
import Telegrammer
import Shared

struct MuteCommand: Command {
    
    let name = "Mute"
    let commands = ["/mute"]
    let syntax = "/mute <name> <hours>"
    let description = "Prevents change notifications for the given entry and duration"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 2 else {
            try showUsage(chatID)
            return
        }
        
        // Parse the arguments
        let name = args[0].trimmingCharacters(in: .whitespaces)
        let hoursStr = args[1].trimmingCharacters(in: .whitespaces)
        
        let hours = Int(hoursStr) ?? 0
        guard (hours > 0) else {
            // No valid int found
            try bot.sendMessage("\(hoursStr) is not a valid integer. Please enter a valid amount of hours > 0.", to: chatID)
            return
        }
        
        // Calculate the unmute time
        let date = Date().addingTimeInterval(.init(hours * 60 * 60))
        
        // Update the entry
        var config = try ConfigParser.getConfig()
        // Use the index, because we want to modify it (URLEntry is a struct, so pointers wouldn't work)
        let entryIndex = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entryIndex != nil else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        var entry = config[entryIndex!]
        entry.unmuteDate = date
        config[entryIndex!] = entry
        try ConfigParser.saveConfig(config)
        try bot.sendMessage("Successfully updated \(entry.name)", to: chatID)
    }
    
}
