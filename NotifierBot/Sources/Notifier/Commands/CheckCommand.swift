//
//  CheckCommand.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation
import Telegrammer

struct CheckCommand: Command {
    
    let name = "Check"
    let commands = ["/check"]
    let syntax = "/check"
    let description = "Performs a manual check if any monitored website changed"
    let permission = BotPermission.admin
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 0 else {
            try showUsage(chatID)
            return
        }
        try bot.sendMessage("Starting check...", to: chatID)
        // TODO: Do async?
        JFUtils.shell("\(kUrlwatchTool)")
        try bot.sendMessage("Check complete", to: chatID)
    }
}
