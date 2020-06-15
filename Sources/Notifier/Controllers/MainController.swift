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
        router[.help, .slashRequired] = setup(.help, onHelp)
        router[.start, .slashRequired] = setup(.start, onHelp)
        router[.list, .slashRequired] = setup(.list, onList)
        router[.listURLs, .slashRequired] = setup(.listURLs, onListURLs)
        router[.listAll, .slashRequired] = setup(.listAll, onListAll)
        router[.add, .slashRequired] = setup(.add, onAdd)
        router[.remove, .slashRequired] = setup(.remove, onRemove)
        router[.update, .slashRequired] = setup(.update, onUpdate)
        router[.check, .slashRequired] = setup(.check, onCheck)
        router[.fetch, .slashRequired] = setup(.fetch, onFetch)
        router[.fetch, .slashRequired] = setup(.fetchURL, onFetchURL)
        router[.getPermissions, .slashRequired] = setup(.getPermissions, onGetPermissions)
        router[.setPermissions, .slashRequired] = setup(.setPermissions, onSetPermissions)
        router[.myID, .slashRequired] = setup(.myID, onMyID)
    }
    
    @discardableResult
    func process(update: Update, properties: [String: AnyObject] = [:]) throws -> Bool {
        // Use the permissions router to check the permissions before processing the command
        return try router.process(update: update, properties: properties)
    }
    
    func setup(_ cmd: JFCommand, _ handler: @escaping ((Context) throws -> Bool)) -> ((Context) throws -> Bool) {
        // Setup before each command
        return { context in
            guard context.command == cmd.name else {
                // If the entered command does not match the command name, keep looking
                // This prevents the execution of the command /list when entering /listall
                return false
            }
            // Execute the real handler
            return try handler(context)
        }
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
        guard context.privateChat else {
            context.respondAsync("Due to privacy reasons, this command can only be executed in a private chat.")
            return true
        }
        return try entryList(context: context, listArea: true, listURLs: true, listAll: true)
    }
    
    private func entryList(context: Context, listArea: Bool, listURLs: Bool, listAll: Bool = false) throws -> Bool {
        var list = "*Monitored Websites:*\n"
        let entries = try ConfigParser.getConfig().filter({ $0.chatID == context.chatId || listAll })
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
    
    func onGetPermissions(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count <= 1 else {
            JFCommand.getPermissions.showUsage(context)
            return true
        }
        let userID: Int64!
        let username: String!
        if args.count == 0 {
            // Use the reply message
            guard let user = context.message?.replyToMessage?.from, user.id != bot.user.id else {
                context.respondAsync("Error: Please respond to a message of a user.")
                return true
            }
            userID = user.id
            username = user.username ?? "<Unknown>"
        } else {
            // Use the ID provided
            guard let id = Int64(args[0].trimmed()) else {
                context.respondAsync("Error: Please provide the user ID as an integer.")
                return true
            }
            userID = id
            username = "\(id)"
        }
        let level = configParser.permissionGroup(user: userID)
        context.respondAsync("The permission level of \(username!) is *\(level.rawValue)*.", parseMode: "markdown")
        return true
    }
    
    func onSetPermissions(context: Context) throws -> Bool {
        let args = context.args.scanWords()
        guard args.count == 1 || args.count == 2 else {
            JFCommand.setPermissions.showUsage(context)
            return true
        }
        let userID: Int64!
        let username: String!
        if args.count == 1 {
            // Use the reply message
            guard let user = context.message?.replyToMessage?.from, user.id != bot.user.id else {
                context.respondAsync("Error: Please respond to a message of a user.")
                return true
            }
            userID = user.id
            username = user.username ?? "<Unknown>"
        } else {
            // Use the ID provided
            guard let id = Int64(args[1].trimmed()) else {
                context.respondAsync("Error: Please provide the user ID as an integer.")
                return true
            }
            userID = id
            username = "\(id)"
        }
        guard let level = BotPermission(rawValue: args[0].trimmed()) else {
            context.respondAsync("Error: Please specify a valid bot permission. (\(BotPermission.allCases.map({ $0.rawValue }).joined(separator: ", ")))")
            return true
        }
        try configParser.setPermissionGroup(user: userID, level: level)
        context.respondAsync("Successfully set the permission level of \(username!) to *\(level.rawValue)*.", parseMode: "markdown")
        return true
    }
    
    func onMyID(context: Context) throws -> Bool {
        guard let id = context.fromId else {
            context.respondAsync("Error: Unable to retrieve ID.")
            return true
        }
        context.respondAsync("The user ID of \(context.message?.from?.username ?? "<Unknown>") is `\(id)`", parseMode: "markdown")
        return true
    }
    
}
