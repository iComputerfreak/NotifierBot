//
//  File.swift
//  
//
//  Created by Jonas Frey on 14.06.20.
//

import Foundation
import TelegramBotSDK

enum BotPermission: String, Comparable, CaseIterable {
    case user = "user"
    case mod = "mod"
    case admin = "admin"
    
    static private let levels: [BotPermission: Int] = [
        .user: 0,
        .mod: 1,
        .admin: 2
    ]
    
    static func <(lhs: BotPermission, rhs: BotPermission) -> Bool {
        return levels[lhs]! < levels[rhs]!
    }
    
    static func >(lhs: BotPermission, rhs: BotPermission) -> Bool {
        return levels[lhs]! > levels[rhs]!
    }
}

struct JFCommand {
    let name: String
    let syntax: String
    var usage: String {
        return "Usage: \(syntax)"
    }
    let description: String
    let permission: BotPermission
    
    init(_ name: String, syntax: String, description: String, permission: BotPermission = .user) {
        self.name = name
        self.syntax = syntax
        self.description = description
        self.permission = permission
    }
    
    func showUsage(_ context: Context) {
        context.respondAsync(usage)
    }
    
    // Static properties
    
    static let allCommands: [JFCommand] = [.help, .start, .add, .remove, .list, .listURLs,
                                           .listAll, .update, .check, .fetch, .fetchURL, .getPermissions, .setPermissions, .myID]
    
    static let help = JFCommand("help",
                                syntax: "/help",
                                description: "Lists all commands and their descriptions",
                                permission: .user)
    
    static let start = JFCommand("start",
                                 syntax: "/start",
                                 description: "Lists all commands and their descriptions",
                                 permission: .user)
    
    static let add = JFCommand("add",
                               syntax: "/add <name> <URL> \\[x y width height]",
                               description: "Adds a new website with an optional screenshot area to the list",
                               permission: .mod)
    
    static let remove = JFCommand("remove",
                                  syntax: "/remove <name>",
                                  description: "Removes an entry from the list",
                                  permission: .mod)
    
    static let list = JFCommand("list",
                                syntax: "/list",
                                description: "Lists all entries including their areas",
                                permission: .user)
    
    static let listURLs = JFCommand("listurls",
                                    syntax: "/listurls",
                                    description: "Lists all entries including their websites",
                                    permission: .user)
    
    static let listAll = JFCommand("listall",
                                   syntax: "/listall",
                                   description: "Lists all entries from all chats",
                                   permission: .admin)
    
    static let update = JFCommand("update",
                                  syntax: "/update <name> <x> <y> <width> <height>",
                                  description: "Updates the screenshot area of an entry",
                                  permission: .mod)
    
    static let check = JFCommand("check",
                                 syntax: "/check",
                                 description: "Performs a manual check if any monitored website changed",
                                 permission: .admin)
    
    static let fetch = JFCommand("fetch",
                                 syntax: "/fetch <name>",
                                 description: "Takes a screenshot with the stored settings and sends it into this chat",
                                 permission: .mod)
    
    static let fetchURL = JFCommand("fetchurl",
                                    syntax: "/fetchurl <URL> \\[x y width height]",
                                    description: "Takes a screenshot of the given website and settings and sends it into this chat",
                                    permission: .mod)
    
    static let getPermissions = JFCommand("getpermissions",
                                          syntax: "/getpermissions",
                                          description: "Returns the permission level of the author of the message, replied to",
                                          permission: .admin)
    
    static let setPermissions = JFCommand("setpermissions",
                                          syntax: "/setpermissions <level>",
                                          description: "Sets the permission level of the author of the message, replied to",
                                          permission: .admin)
    
    static let myID = JFCommand("myid",
                                syntax: "/myid",
                                description: "Returns your User ID",
                                permission: .user)

}
