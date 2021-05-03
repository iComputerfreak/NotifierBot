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
    let syntax = "/add <name> <URL> \\[x y width height]"
    let description = "Adds a new website with an optional screenshot area to the list"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count > 0 else {
            try showUsage(chatID)
            return
        }
        
        // Check if there is a valid URL
        guard let urlIndex = args.lastIndex(where: { $0.starts(with: "http") }) else {
            // No valid URL found
            try bot.sendMessage("Please enter a valid URL, starting with 'http://' or 'https://'", to: chatID)
            return
        }
        // The first argument should be the name, not the URL
        if urlIndex == 0 {
            try showUsage(chatID)
            return
        }
        // Parse the arguments
        let name = args[0..<urlIndex].joined(separator: " ")
        let url = args[urlIndex]
        
        let area: Rectangle!
        if args.count == urlIndex + 5 {
            // If a cropping area was supplied
            let x = Int(args[urlIndex + 1])
            let y = Int(args[urlIndex + 2])
            let width = Int(args[urlIndex + 3])
            let height = Int(args[urlIndex + 4])
            guard x != nil && y != nil && width != nil && height != nil else {
                try bot.sendMessage("Please enter a valid Offset and Size", to: chatID)
                return
            }
            area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        } else if args.count == urlIndex + 1 {
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
