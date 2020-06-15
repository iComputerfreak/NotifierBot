//
//  File.swift
//  
//
//  Created by Jonas Frey on 14.06.20.
//

import Foundation
import TelegramBotSDK

class MainController: Controller {
    
    let urlwatchTool = "/home/botmaster/url_watcher/url_watcher.sh"
    var configParser = ConfigParser()
    var router = Router(bot: bot)
        
    init() {
        router[.help, .slashRequired] = onHelp
        router[.start, .slashRequired] = onHelp
        router[.list, .slashRequired] = onList
        router[.listURLs, .slashRequired] = onListURLs
        router[.listAll, .slashRequired] = onListAll
        router[.add, .slashRequired] = onAdd
        router[.remove, .slashRequired] = onRemove
        router[.update, .slashRequired] = onUpdate
        router[.check, .slashRequired] = onCheck
        router[.fetch, .slashRequired] = onFetch
        router[.fetch, .slashRequired] = onFetchURL
        router[.setPermissions, .slashRequired] = onSetPermissions
        router[.myID, .slashRequired] = onMyID
    }
    
    @discardableResult
    func process(update: Update, properties: [String: AnyObject] = [:]) throws -> Bool {
        // Use the permissions router to check the permissions before processing the command
        return try router.process(update: update, properties: properties)
    }
    
    /// Prints all commands including their usage
    /// - Parameter context: The context of the command
    /// - Throws: `BotError.noPermissions`, if the user does not have the required permission level
    /// - Returns: Whether other commands should be matched
    func onHelp(context: Context) throws -> Bool {
        var usage = "*Usage:*\n"
        for command in JFCommand.allCommands {
            usage += "\(command.syntax) - \(command.description)\n"
        }
        if usage.hasSuffix("\n") {
            usage.removeLast()
        }
        context.respondAsync(usage, parseMode: "markdown")
        return true
    }
    
    func onList(context: Context) throws -> Bool {
        return try entryList(context: context, listArea: true, listURLs: false)
    }
    
    func onListURLs(context: Context) throws -> Bool {
        return try entryList(context: context, listArea: false, listURLs: true)
    }
    
    func onListAll(context: Context) throws -> Bool {
        return try entryList(context: context, listArea: true, listURLs: true)
    }
    
    private func entryList(context: Context, listArea: Bool, listURLs: Bool) throws -> Bool {
        var list = "*Monitored Websites:*\n"
        let entries = try ConfigParser.getConfig().filter({ $0.chatID == context.chatId })
        if entries.isEmpty {
            list += "_None_"
        } else if listArea && listURLs {
            list += entries.map({ "- \($0.name) (Offset: \($0.area.x)/\($0.area.y), Size: \($0.area.width)x\($0.area.height))\n  \($0.url)" }).joined(separator: "\n")
        } else if listURLs {
            list += entries.map({ "- \($0.name): \($0.url)" }).joined(separator: "\n")
        } else if listArea {
            list += entries.map({ "- \($0.name) (Offset: \($0.area.x)/\($0.area.y), Size: \($0.area.width)x\($0.area.height))" }).joined(separator: "\n")
        } else {
            list += entries.map({ "- \($0.name)"}).joined(separator: "\n")
        }
        context.respondAsync(list, parseMode: "markdown")
        return true
    }
    
    func onAdd(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count > 0 else {
            JFCommand.add.showUsage(context)
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
            JFCommand.add.showUsage(context)
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
                context.respondAsync("Please enter a valid Offset and Size")
                return true
            }
            area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        } else if args.count == urlIndex + 1 {
            // No cropping area
            area = .zero
        } else {
            JFCommand.add.showUsage(context)
            return true
        }
        
        guard let chatID = context.chatId else {
            throw BotError.noChatID
        }
        
        // Create the new entry
        let entry = URLEntry(name: name, url: url, area: area, chatID: chatID)
        var config = try ConfigParser.getConfig()
        // Only check for matching names in the same chat
        guard !config.contains(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID }) else {
            context.respondAsync("There is an entry with that name already")
            return true
        }
        config.append(entry)
        try ConfigParser.saveConfig(config)
        
        context.respondAsync("Added '\(name)'")
        return true
    }
    
    func onRemove(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count > 0 else {
            JFCommand.remove.showUsage(context)
            return true
        }
        guard let chatID = context.chatId else {
            throw BotError.noChatID
        }
        
        let name = args.joined(separator: " ")
        var config = try ConfigParser.getConfig()
        // Use .firstIndex instead of .removeFirst to check if there even was an entry that got removed
        let index = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard index != nil else {
            context.respondAsync("There is no entry with the name '\(name)'")
            return true
        }
        config.remove(at: index!)
        try ConfigParser.saveConfig(config)
        context.respondAsync("Successfully removed '\(name)'")
        return true
    }
    
    func onUpdate(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count >= 5 else {
            JFCommand.update.showUsage(context)
            return true
        }
        var arguments = args
        let height = Int(arguments.removeLast())
        let width = Int(arguments.removeLast())
        let y = Int(arguments.removeLast())
        let x = Int(arguments.removeLast())
        // Remaining arguments must be the name
        let name = arguments.joined(separator: " ")
        
        guard x != nil && y != nil && width != nil && height != nil else {
            context.respondAsync("Please enter a valid Offset and Size.")
            return true
        }
        
        guard let chatID = context.chatId else {
            throw BotError.noChatID
        }
        
        var config = try ConfigParser.getConfig()
        // Use the index, because we want to modify it (URLEntry is a struct, so pointers wouldn't work)
        let entryIndex = config.firstIndex(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entryIndex != nil else {
            context.respondAsync("There is no entry with the name '\(name)'")
            return true
        }
        var entry = config[entryIndex!]
        entry.area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        config[entryIndex!] = entry
        try ConfigParser.saveConfig(config)
        context.respondAsync("Successfully updated '\(name)'")
        return true
    }
    
    func onCheck(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count == 0 else {
            JFCommand.check.showUsage(context)
            return true
        }
        context.respondAsync("Starting check...")
        DispatchQueue.main.async {
            // Checking takes up some time, do it async to avoid blocking the bot
            JFUtils.shell("\(self.urlwatchTool)")
            context.respondAsync("Check complete")
        }
        return true
    }
    
    func onFetch(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count > 0 else {
            JFCommand.fetch.showUsage(context)
            return true
        }
        guard let chatID = context.chatId else {
            throw BotError.noChatID
        }
        
        let name = args.joined(separator: " ")
        // Get the settings
        let config = try ConfigParser.getConfig()
        let entry = config.first(where: { $0.name.lowercased() == name.lowercased() && $0.chatID == chatID })
        guard entry != nil else {
            context.respondAsync("There is no entry with the name '\(name)'")
            return true
        }
        DispatchQueue.main.async {
            // Take the screenshot
            JFUtils.takeScreenshot(url: entry!.url, filename: "/tmp/screenshot.png", area: entry!.area)
            // Send the screenshot as file
            // Use the script, because its easier than sending the file in swift
            JFUtils.sendFile(path: "/tmp/screenshot.png", chatID: chatID)
        }
        return true
    }
    
    func onFetchURL(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count == 1 || args.count == 5 else {
            JFCommand.fetchURL.showUsage(context)
            return true
        }
        let url = args[0]
        var area: Rectangle = .zero
        if args.count == 5 {
            let x = Int(args[1])
            let y = Int(args[2])
            let width = Int(args[3])
            let height = Int(args[4])
            guard x != nil && y != nil && width != nil && height != nil else {
                context.respondAsync("Please enter a valid Offset and Size")
                return true
            }
            area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        }
        guard url.hasPrefix("http") else {
            context.respondAsync("Please enter a valid URL, starting with 'http://' or 'https://'")
            return true
        }
        guard let chatID = context.chatId else {
            throw BotError.noChatID
        }
        DispatchQueue.main.async {
            JFUtils.takeScreenshot(url: url, filename: "/tmp/screenshot.png", area: area)
            JFUtils.sendFile(path: "/tmp/screenshot.png", chatID: chatID)
        }
        return true
    }
    
    func onSetPermissions(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count == 2 else {
            JFCommand.setPermissions.showUsage(context)
            return true
        }
        // The mention
        let _ = args[0]
        guard let user = context.message?.entities.first(where: { $0.user != nil })?.user else {
            context.respondAsync("Error: Please mention the user in the message.")
            return true
        }
        guard let level = BotPermission(rawValue: args[1].trimmed()) else {
            context.respondAsync("Error: Please specify a valid bot permission. (\(BotPermission.allCases.map({ $0.rawValue }).joined(separator: ", ")))")
            return true
        }
        try configParser.setPermissionGroup(user: user.id, level: level)
        context.respondAsync("Successfully set the permission level to \(level.rawValue).")
        return true
    }
    
    func onMyID(context: Context) throws -> Bool {
        guard let id = context.fromId else {
            context.respondAsync("Error: Unable to retrieve ID.")
            return true
        }
        context.respondAsync("User ID of \(context.message?.from?.username ?? "<Unknown>"): \(id)")
        return true
    }
    
}
