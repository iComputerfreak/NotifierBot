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
            usage()
            return true
        }
        
        let subcommand = args.removeFirst().lowercased()
        
        do {
            switch subcommand {
            case "list":
                return try list(args)
            case "add":
                return try add(args)
            case "remove":
                return try remove(args)
            case "fetch":
                return try fetch(args)
            case "update":
                return try update(args)
            case "help":
                usage()
                return true
            default:
                usage()
                return true
            }
        } catch ConfigParser.ConfigError.malformedLineSegments(let line) {
            context.respondAsync("Error reading config: Malformed line. Expected name,x,y,width,height,url.\n```\(line)\n```", parseMode: .markdownv2)
            return true
        } catch ConfigParser.ConfigError.malformedIntegers(let line) {
            context.respondAsync("Error reading config: Malformed line. Expected x, y, width and height as Integers.\n```\n\(line)\n```", parseMode: .markdownv2)
            return true
        } catch let e {
            print(e)
            context.respondAsync("Error: \(e.localizedDescription)")
            return true
        }
    }
    
    // MARK: - Subcommands
    
    func usage() {
        context.respondAsync("""
            *Usage:*
            /urlwatch list - List all watched URLs
            /urlwatch add <Name> <URL> \\[x y width height] - Add an URL to the watch list
            /urlwatch remove <Name> - Removes an URL from the watch list
            /urlwatch fetch <Name> - Takes a cropped screenshot of the site and sends it as a file
            /urlwatch update <Name> <x> <y> <width> <height> - Updates the given entry with the new area
            """, parseMode: .markdown)
    }
    
    func list(_ args: [String]) throws -> Bool {
        func usage() {
            context.respondAsync("Usage: /urlwatch list \\[urls]")
        }
        
        var listURLs = false
        guard args.count <= 1 else {
            usage()
            return true
        }
        if args.count == 1 {
            if args.first!.lowercased() == "urls" {
                listURLs = true
            } else {
                usage()
                return true
            }
        }
        
        let config = try ConfigParser.getConfig()
        var list = ""
        if config.isEmpty {
            list = "_None_"
        } else if listURLs {
            list = config.map({ "\($0.name): \($0.url)" }).joined(separator: "\n")
        } else {
            list = config.map({ "\($0.name) (Offset: \($0.area.x)/\($0.area.y), Size: \($0.area.width)x\($0.area.height))" }).joined(separator: "\n")
        }
        context.respondAsync("*Monitored Websites:*\n\(list)", parseMode: .markdown)
        return true
    }
    
    func add(_ args: [String]) throws -> Bool {
        func usage() {
            context.respondAsync("Usage: /urlwatch add <Name> <URL> \\[x y width height]")
        }
        guard args.count > 0 else {
            usage()
            return true
        }
        
        // Check if there is a valid URL
        guard let urlIndex = args.lastIndex(where: { $0.starts(with: "http") }) else {
            // No valid URL found
            context.respondAsync("Please enter a valid URL, starting with 'http://' or 'https://'")
            return true
        }
        // The first argument should be the name, not the URL
        if urlIndex == 0 {
            usage()
            return true
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
                context.respondAsync("Please enter a valid Offset and Size.")
                return true
            }
            area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        } else if args.count == urlIndex + 1 {
            // No cropping area
            area = .zero
        } else {
            usage()
            return true
        }
        
        // Create the new entry
        let entry = URLEntry(name: name, url: url, area: area)
        var config = try ConfigParser.getConfig()
        guard !config.contains(where: { $0.name.lowercased() == name.lowercased() }) else {
            context.respondAsync("There is an entry with that name already.")
            return true
        }
        config.append(entry)
        try ConfigParser.saveConfig(config)
        
        context.respondAsync("Added '\(name)'")
        return true
    }
    
    func remove(_ args: [String]) throws -> Bool {
        func usage() {
            context.respondAsync("Usage: /urlwatch remove <Name>")
        }
        
        guard args.count > 0 else {
            usage()
            return true
        }
        let name = args.joined(separator: " ")
        var config = try ConfigParser.getConfig()
        config.removeAll(where: { $0.name.lowercased() == name.lowercased() })
        try ConfigParser.saveConfig(config)
        context.respondAsync("Successfully removed '\(name)'")
        return true
    }
    
    /// Fetches the screenshot of the given entry and sends it as file
    func fetch(_ args: [String]) throws -> Bool {
        func usage() {
            context.respondAsync("Usage: /urlwatch fetch <Name>")
        }
        guard args.count > 0 else {
            usage()
            return true
        }
        let name = args.joined(separator: " ")
        // Get the settings
        let config = try ConfigParser.getConfig()
        let entry = config.first(where: { $0.name.lowercased() == name.lowercased() })
        guard entry != nil else {
            context.respondAsync("Error: There is no entry with the name '\(name)'")
            return true
        }
        // Take the screenshot
        JFUtils.shell("/usr/bin/firefox --screenshot /tmp/screenshot.png \"\(entry!.url)\"")
        // Send the screenshot as file
        guard let chatID = context.chatId else {
            print("Error: Chat ID not available!")
            return true
        }
        // Use the script, because its easier than sending the file in swift
        JFUtils.shell("/home/botmaster/scripts/telegram.sh -t \(token) -c \(chatID) -f /tmp/screenshot.png")
        return true
    }
    
    /// Updates the offset and size of the given entry
    func update(_ args: [String]) throws -> Bool {
        func usage() {
            context.respondAsync("Usage: /urlwatch update <Name> <x> <y> <width> <height>")
        }
        guard args.count >= 5 else {
            usage()
            return true
        }
        var arguments = args
        let height = Int(arguments.removeLast())
        let width = Int(arguments.removeLast())
        let y = Int(arguments.removeLast())
        let x = Int(arguments.removeLast())
        // Remaining arguments must be the name
        let name = args.joined(separator: " ")
        
        guard x != nil && y != nil && width != nil && height != nil else {
            context.respondAsync("Please enter a valid Offset and Size.")
            return true
        }
        
        var config = try ConfigParser.getConfig()
        // Use the index, because we want to modify it (URLEntry is a struct, so pointers wouldn't work)
        let entryIndex = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() })
        guard entryIndex != nil else {
            context.respondAsync("Error: There is no entry with the name '\(name)'")
            return true
        }
        var entry = config[entryIndex!]
        entry.area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        config[entryIndex!] = entry
        try ConfigParser.saveConfig(config)
        context.respondAsync("Successfully updated '\(name)'")
        return true
    }
    
}
