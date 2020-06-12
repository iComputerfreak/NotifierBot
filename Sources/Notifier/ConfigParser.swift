//
//  File.swift
//  
//
//  Created by Jonas Frey on 12.06.20.
//

import Foundation

struct ConfigParser {
    
    enum ConfigError: Error {
        case malformedLineSegments(String)
        case malformedIntegers(String)
    }
    
    typealias Config = [URLEntry]
    
    static let kURLListFile = "/home/botmaster/url_watcher/urls.list"
    
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
            guard components.count >= 6 else {
                throw ConfigError.malformedLineSegments(line)
            }
            let name = components[0].trimmed()
            let x = Int(components[1].trimmed())
            let y = Int(components[2].trimmed())
            let width = Int(components[3].trimmed())
            let height = Int(components[4].trimmed())
            let url = components[5...].joined(separator: ",").trimmed()
            
            guard x != nil && y != nil && width != nil && height != nil else {
                throw ConfigError.malformedIntegers(line)
            }
            
            entries.append(URLEntry(name: name, url: url, area: Rectangle(x: x!, y: y!, width: width!, height: height!)))
        }
        
        return entries
    }
    
    /// Parses the config back into a string and saves it to disk
    static func saveConfig(_ config: Config) throws {
        var configString = ""
        for l in config {
            configString += "\(l.name),\(l.area.x),\(l.area.y),\(l.area.width),\(l.area.height),\(l.url)\n"
        }
        // Remove the trailing line break
        configString.removeLast()
        try configString.write(toFile: kURLListFile, atomically: true, encoding: .utf8)
    }
    
}

struct URLEntry {
    
    var name: String
    var url: String
    var area: Rectangle
    
}

struct Rectangle {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    
    static let zero = Rectangle(x: 0, y: 0, width: 0, height: 0)
}
