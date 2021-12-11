//
//  SetDelayCommand.swift
//  
//
//  Created by Jonas Frey on 03.06.21.
//

import Foundation
import Telegrammer
import Shared

struct SetDelayCommand: Command {
    
    let name = "Set Delay"
    let commands = ["/setdelay"]
    let syntax = "/setdelay <name> <delay>"
    let description = "Specifies a delay in seconds to wait after the website has been loaded"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 2 else {
            try showUsage(chatID)
            return
        }
        let name = args[0]
        let delay = Int(args[1])
        guard delay != nil else {
            try bot.sendMessage("Please specify a valid integer delay value", to: chatID)
            return
        }
        // Get the settings
        var config = try ConfigParser.getConfig()
        let entryIndex = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entryIndex != nil else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        // Reset the element property
        config[entryIndex!].delay = delay!
        // Save the entry
        try ConfigParser.saveConfig(config)
        
        try bot.sendMessage("Successfully updated the delay of \(name)", to: chatID)
    }
}
