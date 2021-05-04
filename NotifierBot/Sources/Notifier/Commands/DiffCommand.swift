//
//  DiffCommand.swift
//  
//
//  Created by Jonas Frey on 04.05.21.
//

import Foundation
import Telegrammer

struct DiffCommand: Command {
    
    let name = "Diff"
    let commands = ["/diff"]
    let syntax = "/diff <name>"
    let description = "Returns a visual representation of the changed parts of the image."
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count > 0 else {
            try showUsage(chatID)
            return
        }
        let name = args.joined(separator: " ")
        // Check if an entry with this name exists
        let config = try ConfigParser.getConfig()
        guard let entry = config.first(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID }) else {
            try bot.sendMessage("There is no entry with the name '\(name)'", to: chatID)
            return
        }
        let realName = entry.name
        // Send the diff file and the contents of the ncc file
        let nccInfo = try? String(contentsOfFile: "\(mainDirectory!)/urlwatcher/images/\(realName)/\(nccFile)")
        JFUtils.sendImage(path: "\(mainDirectory!)/urlwatcher/images/\(realName)/\(diffFile)", chatID: chatID, text: nccInfo)
    }
}
