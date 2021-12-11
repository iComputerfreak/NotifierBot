//
//  File.swift
//  
//
//  Created by Jonas Frey on 22.07.21.
//

import Foundation
import Shared

enum BashResult: Equatable {
    case success
    case failure(Int32)
    case argumentError
    
    init(status: Int32) {
        if status == 0 {
            self = .success
        } else {
            self = .failure(status)
        }
    }
}

func directory(for entry: URLEntry) -> String {
    // Use the name and chat id to create unique directories
    return "\(kImagesDirectory)/\(entry.name).\(entry.chatID)"
}

@discardableResult
func bash(_ command: String, arguments: [String] = [], noEnv: Bool = false, currentDirectory: String? = nil, standardOutput: Any? = nil, standardError: Any? = nil) throws -> BashResult {
    let proc = Process()
    if noEnv {
        proc.executableURL = URL(fileURLWithPath: command)
        proc.arguments = arguments
    } else {
        var env = ProcessInfo.processInfo.environment
        var path = env["PATH"]! as String
        path = "/usr/local/bin:" + path
        env["PATH"] = path
        proc.environment = env
        
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = [command] + arguments
    }
    if let currentDirectory = currentDirectory {
        proc.currentDirectoryPath = currentDirectory
    }
    proc.standardOutput = standardOutput ?? FileHandle.standardOutput
    proc.standardError = standardError ?? FileHandle.standardError
    try proc.run()
    proc.waitUntilExit()
    // Return value 0 is success, everything else it failure
    return BashResult(status: proc.terminationStatus)
}

extension FileManager {
    func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
