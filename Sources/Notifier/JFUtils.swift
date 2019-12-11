//
//  JFUtils.swift
//  
//
//  Created by Jonas Frey on 11.12.19.
//

import Foundation

struct JFUtils {
    
    /// Executes a shell command using bash and returns the result
    /// - Parameter command: The command to execute using bash
    @discardableResult static func shell(_ command: String, includeErrors: Bool = false) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        if includeErrors {
            task.standardError = pipe
        }
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        
        return output
    }
    
}
