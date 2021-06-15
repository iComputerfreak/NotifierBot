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
        shell("\(kScreenshotScript) \(filename) \"\(url)\"")
        if area.width != 0 && area.height != 0 {
            // Crop the screenshot
            shell("\(kConvertPath) \(filename) -crop \(area.width)x\(area.height)+\(area.x)+\(area.y) \(filename)")
        }
    }
    
    static func sendFile(path: String, chatID: Int64, text: String? = nil) {
        sendImageOrFile(path: path, chatID: chatID, isFile: true, text: text)
    }
    
    static func sendImage(path: String, chatID: Int64, text: String? = nil) {
        sendImageOrFile(path: path, chatID: chatID, isFile: false, text: text)
    }
    
    static private func sendImageOrFile(path: String, chatID: Int64, isFile: Bool, text: String? = nil) {
        var command = "\(kTelegramScript) -t \(token!) -c \(chatID) -\(isFile ? "f" : "i") \"\(path)\""
        if let text = text {
            // Encase the lines in parantheses
            let lines = text.components(separatedBy: .newlines).map({ "\"\($0)\"" })
            // Join the lines using line breaks
            command += " \(lines.joined(separator: "$'\n'"))"
        }
        shell(command)
    }
    
    static func entryList(_ entries: [URLEntry], listURLs: Bool = false) -> String {
        var list = ["*Monitored Websites:*"]
        if entries.isEmpty {
            list.append("_None_")
        } else if listURLs {
            for entry in entries {
                list.append("- \(entry.name): \(entry.url)".escaped())
            }
        } else {
            for entry in entries {
                list.append("- \(entry.name)".escaped())
            }
        }
        return list.joined(separator: "\n")
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
