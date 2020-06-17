//
//  File.swift
//  
//
//  Created by Jonas Frey on 12.06.20.
//

import Foundation

class ConfigParser {
    
    typealias Config = [URLEntry]
    
    var permissions: [Int64: BotPermission] = parsePermissions()
    
    init() {}
    
    /// Parses the file on disk into an internal structure
    static func getConfig() throws -> Config {
        let config = (try? String(contentsOfFile: kURLListFile)) ?? ""
        var entries: [URLEntry] = []
        for line in config.components(separatedBy: .newlines) {
            if line.isEmpty {
                continue
            }
            let components = line.components(separatedBy: ",")
            // Name, x, y, width, height, url (url may contain comma)
            guard components.count >= 7 else {
                throw BotError.malformedLineSegments(line)
            }
            let name = components[0].trimmed()
            let x = Int(components[1].trimmed())
            let y = Int(components[2].trimmed())
            let width = Int(components[3].trimmed())
            let height = Int(components[4].trimmed())
            let chatID = Int64(components[5].trimmed())
            let url = components[6...].joined(separator: ",").trimmed()
            
            guard x != nil && y != nil && width != nil && height != nil && chatID != nil else {
                throw BotError.malformedIntegers(line)
            }
            
            entries.append(URLEntry(name: name, url: url, area: Rectangle(x: x!, y: y!, width: width!, height: height!), chatID: chatID!))
        }
        
        return entries
    }
    
    /// Parses the config back into a string and saves it to disk
    static func saveConfig(_ config: Config) throws {
        var configString = ""
        for l in config {
            configString += "\(l.name),\(l.area.x),\(l.area.y),\(l.area.width),\(l.area.height),\(l.chatID),\(l.url)\n"
        }
        // Remove the trailing line break
        configString.removeLast()
        try configString.write(toFile: kURLListFile, atomically: true, encoding: .utf8)
    }
    
    static func parsePermissions() -> [Int64: BotPermission] {
        guard let permissionsFile = try? String(contentsOfFile: kPermissionsFile) else {
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
            let userID = Int64(components[0].trimmed())
            let permissionLevel = BotPermission(rawValue: components[1].trimmed())
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
        try file.write(toFile: kPermissionsFile, atomically: true, encoding: .utf8)
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
    
}

struct Rectangle {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    
    static let zero = Rectangle(x: 0, y: 0, width: 0, height: 0)
}
