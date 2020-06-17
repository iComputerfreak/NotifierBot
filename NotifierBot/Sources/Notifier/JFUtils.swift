//
//  JFUtils.swift
//  
//
//  Created by Jonas Frey on 11.12.19.
//

import Foundation
import TelegramBotSDK


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
    
    static func takeScreenshot(url: String, filename: String, area: Rectangle = .zero) {
        shell("\(kPythonPath) \(kScreenshotScript) \(filename) \"\(url)\"")
        if area.width != 0 && area.height != 0 {
            // Crop the screenshot
            shell("\(kConvertPath) \(filename) -crop \(area.width)x\(area.height)+\(area.x)+\(area.y) \(filename)")
        }
    }
    
    static func sendFile(path: String, chatID: Int64) {
        sendImageOrFile(path: path, chatID: chatID, isFile: true)
    }
    
    static func sendImage(path: String, chatID: Int64) {
        sendImageOrFile(path: path, chatID: chatID, isFile: false)
    }
    
    static private func sendImageOrFile(path: String, chatID: Int64, isFile: Bool) {
        shell("\(kTelegramScript) -t \(token) -c \(chatID) -\(isFile ? "f" : "i") \(path)")
    }
    
}

extension Router {
    // Subscripts taking JFCommand
    subscript(_ command: JFCommand, _ options: Command.Options) -> (Context) throws -> Bool {
        get { fatalError("Not implemented") }
        set { add(Command(command.name, options: options), newValue) }
    }
    
    subscript(_ command: JFCommand) -> (Context) throws -> Bool {
        get { fatalError("Not implemented") }
        set { add(Command(command.name), newValue) }
    }
}
