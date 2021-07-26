//
//  File.swift
//  
//
//  Created by Jonas Frey on 12.06.20.
//

import Foundation

enum ConfigError: Error {
    case malformedLineSegments(String)
    case malformedIntegers(String)
}

class ConfigParser {
    
    static let shared = ConfigParser()
    
    typealias Config = [URLEntry]
    
    var permissions: [Int64: BotPermission] = parsePermissions()
    
    private init() {}
    
    /// Parses the file on disk into an internal structure
    static func getConfig() throws -> Config {
        let config = (try? String(contentsOfFile: urlListFile)) ?? ""
        var entries: [URLEntry] = []
        for line in config.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespaces).isEmpty
                || line.trimmingCharacters(in: .whitespaces).starts(with: "#") {
                continue
            }
            let components = line.components(separatedBy: ",")
            // Name, x, y, width, height, url (url may contain comma)
            guard components.count >= 9 else {
                throw ConfigError.malformedLineSegments(line)
            }
            var args = components
            
            func nextArg() -> String { args.removeFirst().trimmingCharacters(in: .whitespaces) }
            
            let name = nextArg()
            let x = Int(nextArg())
            let y = Int(nextArg())
            let width = Int(nextArg())
            let height = Int(nextArg())
            let delay = Int(nextArg())
            let captureElement = nextArg()
            let clickElement = nextArg()
            let waitElement = nextArg()
            let chatID = Int64(nextArg())
            // URL is the rest
            let url = args.joined(separator: ",").trimmingCharacters(in: .whitespaces)
            
            guard x != nil && y != nil && width != nil && height != nil && chatID != nil, delay != nil else {
                throw ConfigError.malformedIntegers(line)
            }
            
            entries.append(URLEntry(
                            name: name,
                            url: url,
                            area: Rectangle(x: x!, y: y!, width: width!, height: height!),
                            chatID: chatID!,
                            delay: delay!,
                            captureElement: captureElement,
                            clickElement: clickElement,
                            waitElement: waitElement))
        }
        
        return entries
    }
    
    /// Parses the config back into a string and saves it to disk
    static func saveConfig(_ config: Config) throws {
        var configString = ""
        for l in config {
            configString += "\(l.name),\(l.area.x),\(l.area.y),\(l.area.width),\(l.area.height),\(l.delay),\(l.captureElement),\(l.clickElement),\(l.waitElement),\(l.chatID),\(l.url)\n"
        }
        // Remove the trailing line break
        configString.removeLast()
        try configString.write(toFile: urlListFile, atomically: true, encoding: .utf8)
    }
    
    static func parsePermissions() -> [Int64: BotPermission] {
        guard let permissionsFile = try? String(contentsOfFile: permissionsFile) else {
            return [:]
        }
        var permissions: [Int64: BotPermission] = [:]
        for line in permissionsFile.components(separatedBy: .newlines) {
            if line.isEmpty { continue }
            let components = line.components(separatedBy: ":")
            guard components.count == 2 else {
                print("Error reading permissions: Malformed permission. Expected userID: permissionLevel.\n    \(line)")
                print("Skipping this permission...")
                continue
            }
            let userID = Int64(components[0].trimmingCharacters(in: .whitespaces))
            let permissionLevel = BotPermission(rawValue: components[1].trimmingCharacters(in: .whitespaces))
            guard userID != nil && permissionLevel != nil else {
                print("Error reading permissions: Malformed permission. Expected userID: permissionLevel.\n    \(line)")
                print("Skipping this permission...")
                continue
            }
            permissions[userID!] = permissionLevel!
        }
        return permissions
    }
    
    func savePermissions() throws {
        let file = permissions.map { (userID: Int64, permission: BotPermission) in
            "\(userID): \(permission.rawValue)"
        }.joined(separator: "\n")
        try file.write(toFile: permissionsFile, atomically: true, encoding: .utf8)
    }
    
    func permissionGroup(user: Int64) -> BotPermission {
        return permissions[user] ?? .user
    }
    
    func setPermissionGroup(user: Int64, level: BotPermission) throws {
        permissions[user] = level
        try savePermissions()
    }
    
}

struct URLEntry {
    
    var name: String
    var url: String
    var area: Rectangle
    var chatID: Int64
    var delay: Int = 0
    var captureElement: String = ""
    var clickElement: String = ""
    var waitElement: String = ""
    
}

struct Rectangle {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    
    static let zero = Rectangle(x: 0, y: 0, width: 0, height: 0)
}
