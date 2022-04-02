//
//  SetWaitElementCommand.swift
//
//
//  Created by Jonas Frey on 03.06.21.
//

import Foundation
import Telegrammer
import Shared

struct SetWaitElementCommand: Command {
    
    let name = "Set Wait Element"
    let commands = ["/setwaitelement"]
    let syntax = "/setwaitelement <name> [html element]"
    let description = "Specifies which HTML element to wait for before taking the screenshot"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count >= 1 else {
            try showUsage(chatID)
            return
        }
        let name = args[0]
        // Get the settings
        var config = try ConfigParser.getConfig()
        let entryIndex = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entryIndex != nil else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        // Reset the element property
        config[entryIndex!].waitElement = ""
        if args.count > 1 {
            let element = args[1...].joined(separator: " ")
            guard !element.contains(configSeparator) else {
                try bot.sendMessage("Please specify a HTML element that does not contain '\(configSeparator)'", to: chatID)
                return
            }
            // If there was a new element supplied, set it
            config[entryIndex!].waitElement = element
        }
        // Save the entry
        try ConfigParser.saveConfig(config)
        
        if args.count == 1 {
            try bot.sendMessage("Successfully removed wait element of \(name)", to: chatID)
        } else {
            try bot.sendMessage("Successfully updated wait element of \(name)", to: chatID)
        }
    }
}
