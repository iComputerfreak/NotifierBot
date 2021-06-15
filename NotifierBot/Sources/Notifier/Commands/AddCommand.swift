//
//  AddCommand.swift
//  
//
//  Created by Jonas Frey on 01.05.21.
//

import Foundation
import Telegrammer

struct AddCommand: Command {
    
    let name = "Add"
    let commands = ["/add"]
    let syntax = "/add <name> <URL> [x y width height]"
    let description = "Adds a new website with an optional screenshot area to the list"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count >= 2 else {
            try showUsage(chatID)
            return
        }
        
        // Parse the arguments
        let name = args[0]
        let url = args[1]
        
        // Check if there is a valid URL
        guard url.starts(with: "http") else {
            // No valid URL found
            try bot.sendMessage("\(url) is not a valid URL. Please enter a valid URL, starting with 'http://' or 'https://'", to: chatID)
            return
        }
        
        let area: Rectangle!
        // If we have name, url, x, y, width, height (6 arguments)
        if args.count == 6 {
            // If a cropping area was supplied
            let x = Int(args[2])
            let y = Int(args[3])
            let width = Int(args[4])
            let height = Int(args[5])
            guard x != nil && y != nil && width != nil && height != nil else {
                try bot.sendMessage("Please enter a valid Offset and Size", to: chatID)
                return
            }
            area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        } else if args.count == 2 {
            // No cropping area
            area = .zero
        } else {
            try showUsage(chatID)
            return
        }
        
        // Create the new entry
        let entry = URLEntry(name: name, url: url, area: area, chatID: chatID)
        var config = try ConfigParser.getConfig()
        // Only check for matching names in the same chat
        guard !config.contains(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID }) else {
            try bot.sendMessage("There is an entry with that name already", to: chatID)
            return
        }
        config.append(entry)
        try ConfigParser.saveConfig(config)
        
        try bot.sendMessage("Added '\(name)'", to: chatID)
    }
    
}
