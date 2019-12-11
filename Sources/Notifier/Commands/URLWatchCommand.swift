//
//  URLWatchCommand.swift
//  
//
//  Created by Jonas Frey on 11.12.19.
//

import Foundation
import TelegramBotSDK

struct URLWatchCommand: BotCommand {
    
    let context: Context
    
    func run() -> Bool {
        var args = context.args.scanWords()
        
        guard args.count != 0 else {
            // Print Usage
            return usage()
        }
        
        let subcommand = args.removeFirst()
        
        switch subcommand {
        case "list":
            return list(args)
        case "add":
            return add(args)
        case "remove":
            return remove(args)
        default:
            return usage()
        }
    }
    
    // MARK: - Subcommands
    
    func usage() -> Bool {
        context.respondAsync("""
            *Usage:*
            /urlwatch list - List all watched URLs
            /urlwatch add <Name> <URL> - Add an URL to the watch list
            /urlwatch remove <ID> - Removes an URL from the watch list
            """, parse_mode: "Markdown")
        return false
    }
    
    func list(_ args: [String]) -> Bool {
        let list = JFUtils.shell("urlwatch --list")
        context.respondAsync("*Monitored Websites:*\n\(list.isEmpty ? "None" : list)", parse_mode: "Markdown")
        return true
    }
    
    func add(_ args: [String]) -> Bool {
        guard args.count == 2 else {
            context.respondAsync("Usage: /urlwatch add <Name> <URL>")
            return false
        }
        let name = args[0].trimmed()
        let url = args[1].trimmed()
        let result = JFUtils.shell("urlwatch --add url=\(url),name=\(name)", includeErrors: true)
        context.respondAsync(result)
        return true
    }
    
    func remove(_ args: [String]) -> Bool {
        guard args.count == 1 else {
            context.respondAsync("Usage: /urlwatch remove <ID>")
            return false
        }
        let id = args[0]
        let result = JFUtils.shell("urlwatch --delete \(id)", includeErrors: true)
        context.respondAsync(result)
        return true
    }
    
}
