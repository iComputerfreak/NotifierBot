//
//  URLWatchCommand.swift
//  
//
//  Created by Jonas Frey on 11.12.19.
//

import Foundation
import TelegramBotSDK

struct URLWatchCommand: BotCommand {
    
    let urlWatchConfig = "/home/botmaster/.config/urlwatch/urls.yaml"
    
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
        context.respondSync("*Monitored Websites:*\n\(list.isEmpty ? "None" : list)", parse_mode: "Markdown")
        return true
    }
    
    func add(_ args: [String]) -> Bool {
        guard args.count == 2 else {
            context.respondAsync("Usage: /urlwatch add <Name> <URL>")
            return false
        }
        let name = args[0].trimmed()
        let url = args[1].trimmed()
        var filter: String? = nil
        if url.contains("steampowered.com") {
            filter = "element-by-class:page_content,html2text"
        } else if url.contains("instant-gaming.com") {
            filter = "element-by-class:buy,strip"
        }
        do {
            var file = try String(contentsOfFile: urlWatchConfig, encoding: .utf8)
            file += """
            
            ---
            kind: url
            name: \(name)
            url: \(url)\(filter == nil ? "" : "\nfilter: \(filter!)")
            """
            try file.write(toFile: urlWatchConfig, atomically: true, encoding: .utf8)
        } catch let e {
            print(e)
            context.respondSync("Error: \(e.localizedDescription)")
        }
        //let result = JFUtils.shell("urlwatch --add url=\(url),name=\(name)", includeErrors: true)
        context.respondSync("Adding <url name='\(name)' url='\(url)'>")
        return true
    }
    
    func remove(_ args: [String]) -> Bool {
        guard args.count == 1 else {
            context.respondAsync("Usage: /urlwatch remove <ID>")
            return false
        }
        let id = args[0]
        let result = JFUtils.shell("urlwatch --delete \(id)", includeErrors: true)
        context.respondSync(result)
        return true
    }
    
}
