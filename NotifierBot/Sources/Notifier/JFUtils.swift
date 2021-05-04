//
//  JFUtils.swift
//  
//
//  Created by Jonas Frey on 11.12.19.
//

import Foundation
import Telegrammer


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
        shell("\(kTelegramScript) -t \(token!) -c \(chatID) -\(isFile ? "f" : "i") \(path)")
    }
    
    static func entryList(_ entries: [URLEntry], listArea: Bool, listURLs: Bool, listAll: Bool = false) -> String {
        var list = "*Monitored Websites:*\n"
        if entries.isEmpty {
            list += "_None_"
        } else if listArea && listURLs {
            list += entries.map({ "- \($0.name) (Offset: \($0.area.x)/\($0.area.y), Size: \($0.area.width)x\($0.area.height))\n  \($0.url)" }).joined(separator: "\n").escaped()
        } else if listURLs {
            list += entries.map({ "- \($0.name): \($0.url)" }).joined(separator: "\n").escaped()
        } else if listArea {
            list += entries.map({ "- \($0.name) (Offset: \($0.area.x)/\($0.area.y), Size: \($0.area.width)x\($0.area.height))" }).joined(separator: "\n").escaped()
        } else {
            list += entries.map({ "- \($0.name)"}).joined(separator: "\n").escaped()
        }
        return list
    }
    
}

extension Dispatcher {
    func add(command: Command, to group: HandlerGroup = .zero) {
        self.handlersQueue.add(command.handler, to: group)
    }
}

extension Update {
    func chatID() throws -> Int64 {
        guard let message = self.message else {
            throw JFBotError.noMessage
        }
        return message.chat.id
    }
    
    func args() throws -> [String] {
        guard let message = self.message else {
            throw JFBotError.noMessage
        }
        guard let messageText = message.text else {
            throw JFBotError.noMessageText
        }
        // Drop the command itself from the arguments
        return Array(messageText.components(separatedBy: " ").dropFirst())
    }
}

extension Bot {
    
    /// Sends a message with the default parameters for this bot
    @discardableResult
    func sendMessage(_ text: String, to chatID: Int64, parseMode: ParseMode? = nil, disableWebPagePreview: Bool? = true,
                     disableNotification: Bool? = true, replyToMessageId: Int? = nil, replyMarkup: ReplyMarkup? = nil) throws -> Future<Message> {
        return try self.sendMessage(params: .init(chatId: .chat(chatID), text: text, parseMode: parseMode, disableWebPagePreview: disableWebPagePreview,
                                                  disableNotification: disableNotification, replyToMessageId: replyToMessageId, replyMarkup: replyMarkup))
    }
    
}

extension String {
    func escaped() -> String {
        // Escape characters that are reserved in MarkdownV2 (https://core.telegram.org/bots/api#markdownv2-style)
        var text = self
        for character in ["_", "*", "[", "]", "(", ")", "~", "`", ">", "#", "+", "-", "=", "|", "{", "}", ".", "!"] {
            text = text.replacingOccurrences(of: character, with: "\\" + character)
        }
        return text
    }
}
