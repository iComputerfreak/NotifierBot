//
//  FetchCommand.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation
import Telegrammer

struct FetchCommand: Command {
    
    let name = "Fetch"
    let commands = ["/fetch"]
    let syntax = "/fetch <name>"
    let description = "Takes a screenshot with the stored settings and sends it into this chat"
    let permission = BotPermission.mod
    
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
        let entry = config.first(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entry != nil else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        // Take the screenshot
        JFUtils.takeScreenshot(url: entry!.url, filename: "/tmp/screenshot.png", area: entry!.area)
        // Send the screenshot as file
        // Use the script, because its easier than sending the file in swift
        JFUtils.sendFile(path: "/tmp/screenshot.png", chatID: chatID)
    }
}
