//
//  URLWatchCommand.swift
//  
//
//  Created by Jonas Frey on 11.12.19.
//

import Foundation
import TelegramBotSDK

struct URLWatchCommand: BotCommand {
    
    let kURLListFile = "/home/botmaster/url_watcher/urls.list"
    
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
            /urlwatch add <Name> <URL> [x y width height] - Add an URL to the watch list
            /urlwatch remove <Name> - Removes an URL from the watch list
            """, parseMode: "Markdown")
        return false
    }
    
    func list(_ args: [String]) -> Bool {
        guard let file = try? String(contentsOfFile: kURLListFile) else {
            print("Error reading urls.list")
            context.respondAsync("*Monitored Websites:*\nNone", parseMode: "Markdown")
            return true
        }
        
        let list: [String] = file.components(separatedBy: .newlines).compactMap { (line: String) in
            if line.isEmpty {
                return nil
            }
            let components = line.components(separatedBy: ",")
            if components.count < 6 {
                print("Invalid format: '\(line)'")
                context.respondAsync("ERROR: Invalid Format in urls.list. Check the console for errors.")
                return nil
            }
            let name = components[0]
            let x = components[1]
            let y = components[2]
            let width = components[3]
            let height = components[4]
            //let url = components[5...].joined(separator: ",")
            if (width == "0" || height == "0") {
                return "\(name)"
            }
            return "\(name) (Offset: \(x)/\(y), Size: \(width)x\(height))"
        }
        context.respondSync("*Monitored Websites:*\n\(list.isEmpty ? "None" : list.joined(separator: "\n"))", parseMode: "Markdown")
        return true
    }
    
    func add(_ args: [String]) -> Bool {
        
        // Interactive Mode
        if args.count == 0 {
            context.respondAsync("Usage: /urlwatch add <Name> <URL> [x y width height]")
        } else {
            // Check if there is a valid URL
            guard let urlIndex = args.lastIndex(where: { $0.starts(with: "http") }) else {
                // No valid URL found
                context.respondAsync("Please enter a valid URL, starting with 'http://' or 'https://'")
                return true
            }
            
            if urlIndex == 0 {
                context.respondAsync("Usage: /urlwatch add <Name> <URL> [x y width height]")
                return true
            }
            let name = args[0..<urlIndex].joined(separator: " ")
            let url = args[urlIndex]
                        
            let rect: CGRect!
            if args.count == urlIndex + 5 {
                // If a cropping area was supplied
                let x = Int(args[urlIndex + 1])
                let y = Int(args[urlIndex + 2])
                let width = Int(args[urlIndex + 3])
                let height = Int(args[urlIndex + 4])
                if x == nil || y == nil || width == nil || height == nil {
                    context.respondAsync("Please enter a valid Offset and Size.")
                    return true
                }
                rect = CGRect(x: x!, y: y!, width: width!, height: height!)
            } else if args.count == urlIndex + 1 {
                // No cropping area
                rect = .zero
            } else {
                context.respondAsync("Usage: /urlwatch add <Name> <URL> [x y width height]")
                return true
            }
            
            // Save the new entry
            let configString = "\(name),\(rect.origin.x),\(rect.origin.y),\(rect.size.width),\(rect.size.height),\(url)"
            if !FileManager.default.fileExists(atPath: kURLListFile) {
                // Create new file
                try? configString.write(toFile: kURLListFile, atomically: true, encoding: .utf8)
            } else {
                // Append
                var config = (try? String(contentsOfFile: kURLListFile)) ?? ""
                if !config.hasSuffix("\n") {
                    config += "\n"
                }
                config += configString
                try? config.write(toFile: kURLListFile, atomically: true, encoding: .utf8)
            }
            
            context.respondSync("Added '\(name)'")
        }
        
        return true
    }
    
    func remove(_ args: [String]) -> Bool {
        guard args.count > 0 else {
            context.respondAsync("Usage: /urlwatch remove <Name>")
            return true
        }
        let name = args.joined(separator: " ")
        var config = ((try? String(contentsOfFile: kURLListFile)) ?? "").components(separatedBy: .newlines)
        config.removeAll(where: { line in
            return line.hasPrefix("\(name),")
        })
        // Save the config back
        try? config.joined(separator: "\n").write(toFile: kURLListFile, atomically: true, encoding: .utf8)
        context.respondAsync("Successfully removed '\(name)'")
        return true
    }
    
}
