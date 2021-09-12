//
//  InfoCommand.swift
//
//
//  Created by Jonas Frey on 01.05.21.
//

import Foundation
import Telegrammer

struct InfoCommand: Command {
    
    let name = "Info"
    let commands = ["/info"]
    let syntax = "/info <name>"
    let description = "Shows more information about a specific entry"
    let permission = BotPermission.user
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 1 else {
            try showUsage(chatID)
            return
        }
        let name = args[0]
        // Get the settings
        let config = try ConfigParser.getConfig()
        let entryIndex = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entryIndex != nil else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        
        // Show information about the entry
        try bot.sendMessage(infoText(for: config[entryIndex!]), to: chatID, parseMode: .markdownV2)
    }
    
    private func infoText(for e: URLEntry) -> String {
        var lines = ["*\(e.name.escaped()):*"]
        // Escape '-' with backslash
        lines.append("- URL: \(e.url)".escaped())
        if e.area.height != 0 && e.area.width != 0 {
            lines.append("- Area: (\(e.area.x), \(e.area.y), \(e.area.width), \(e.area.height))".escaped())
        }
        if e.delay > 0 {
            lines.append("- Delay: \(e.delay)".escaped())
        }
        if !e.captureElement.isEmpty {
            lines.append("- Capture Element: ".escaped() + "`\(e.captureElement.escaped())`")
        }
        if !e.clickElement.isEmpty {
            lines.append("- Click Element: ".escaped() + "`\(e.clickElement.escaped())`")
        }
        if !e.waitElement.isEmpty {
            lines.append("- Wait Element: ".escaped() + "`\(e.waitElement.escaped())`")
        }
        return lines.joined(separator: "\n")
    }
    
}
