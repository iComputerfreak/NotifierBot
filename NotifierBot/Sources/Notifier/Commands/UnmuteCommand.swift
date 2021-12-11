//
//  UnmuteCommand.swift
//  
//
//  Created by Jonas Frey on 03.12.21.
//

import Foundation
import Telegrammer
import Shared

struct UnmuteCommand: Command {
    
    let name = "Unmute"
    let commands = ["/unmute"]
    let syntax = "/unmute <name>"
    let description = "Resumes notifications for the given entry"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 1 else {
            try showUsage(chatID)
            return
        }
        
        // Parse the arguments
        let name = args[0].trimmingCharacters(in: .whitespaces)
        
        // Update the entry
        var config = try ConfigParser.getConfig()
        // Use the index, because we want to modify it (URLEntry is a struct, so pointers wouldn't work)
        let entryIndex = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entryIndex != nil else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        var entry = config[entryIndex!]
        // Set the unmute date to "now" so that the script will send the neccessary unmute messages
        entry.unmuteDate = Date()
        config[entryIndex!] = entry
        try ConfigParser.saveConfig(config)
        try bot.sendMessage("Successfully updated \(entry.name)", to: chatID)
    }
    
}
