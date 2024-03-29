//
//  File.swift
//  
//
//  Created by Jonas Frey on 12.06.20.
//

import Foundation

public class ConfigParser {
    
    public static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()
    
    public static let shared = ConfigParser()
    
    public typealias Config = [URLEntry]
    
    public var permissions: [Int64: BotPermission] = parsePermissions()
    
    private init() {}
    
    /// Parses the file on disk into an internal structure
    public static func getConfig() throws -> Config {
        let config = (try? String(contentsOfFile: kURLListFile)) ?? ""
        var entries: [URLEntry] = []
        for line in config.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespaces).isEmpty
                || line.trimmingCharacters(in: .whitespaces).starts(with: "#") {
                continue
            }
            let components = line.components(separatedBy: configSeparator)
            // Name, x, y, width, height, url (url may contain comma)
            guard components.count >= 9 else {
                throw JFConfigError.malformedLineSegments(line)
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
            let unmuteDateStr = nextArg()
            let chatID = Int64(nextArg())
            // URL is the rest
            let url = args.joined(separator: configSeparator).trimmingCharacters(in: .whitespaces)
            
            guard x != nil && y != nil && width != nil && height != nil && chatID != nil, delay != nil else {
                throw JFConfigError.malformedIntegers(line)
            }
            
            let unmuteDate = dateFormatter.date(from: unmuteDateStr)
            
            entries.append(URLEntry(
                            name: name,
                            url: url,
                            area: Rectangle(x: x!, y: y!, width: width!, height: height!),
                            chatID: chatID!,
                            delay: delay!,
                            captureElement: captureElement,
                            clickElement: clickElement,
                            waitElement: waitElement,
                            unmuteDate: unmuteDate))
        }
        
        return entries
    }
    
    /// Parses the config back into a string and saves it to disk
    public static func saveConfig(_ config: Config) throws {
        var configLines: [String] = []
        for l in config {
            var unmuteDateStr = ""
            if let unmuteDate = l.unmuteDate {
                unmuteDateStr = dateFormatter.string(from: unmuteDate)
            }
            configLines.append([
                l.name,
                "\(l.area.x)",
                "\(l.area.y)",
                "\(l.area.width)",
                "\(l.area.height)",
                "\(l.delay)",
                l.captureElement,
                l.clickElement,
                l.waitElement,
                unmuteDateStr,
                "\(l.chatID)",
                l.url
            ].joined(separator: configSeparator))
        }
        try configLines.joined(separator: "\n").write(toFile: kURLListFile, atomically: true, encoding: .utf8)
    }
    
    public static func parsePermissions() -> [Int64: BotPermission] {
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
    
    public func savePermissions() throws {
        let file = permissions.map { (userID: Int64, permission: BotPermission) in
            "\(userID): \(permission.rawValue)"
        }.joined(separator: "\n")
        try file.write(toFile: kPermissionsFile, atomically: true, encoding: .utf8)
    }
    
    public func permissionGroup(user: Int64) -> BotPermission {
        return permissions[user] ?? .user
    }
    
    public func setPermissionGroup(user: Int64, level: BotPermission) throws {
        permissions[user] = level
        try savePermissions()
    }
    
}
