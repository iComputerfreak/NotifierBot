//
//  File 2.swift
//  
//
//  Created by Jonas Frey on 30.04.21.
//

import Foundation
import Telegrammer

class JFErrorHandler {
    
    static let shared: JFErrorHandler = JFErrorHandler()
    
    func handle(_ error: JFBotError, update: Update) {
        
        func sendError(_ userMessage: String) {
            if let chatID = update.message?.chat.id {
                _ = try? bot.sendMessage(userMessage, to: chatID)
            }
        }
        
        switch error {
        case .malformedLineSegments(let line):
            sendError("Config Error: Malformed line. Check the log for additional information.")
            print("Error reading config: Malformed line. Expected 'name,x,y,width,height,chatID,url':\n    \(line)")
        case .malformedIntegers(let line):
            sendError("Config Error: Malformed line. Check the log for additional information.")
            print("Error reading config: Malformed line. Expected x, y, width and height as Integers.\n    \(line)")
        case .malformedPermissions(let line):
            sendError("Permissions Error: Malformed line. Check the log for additional information.")
            print("Error reading permissions: Malformed line: \(line)")
        case .noMessage:
            sendError("Error: Unable to retrieve message.")
            print("Error: Unable to retrieve message containing this command.")
        case .noMessageText:
            sendError("Error: Unable to retrieve message text.")
            print("Error: Unable to retrieve message text containing this command.")
        case .noPermissions(let command):
            sendError("This action requires the permission level *\(command.permission.rawValue)*.")
            var name = "\(update.message?.from?.username ?? "Unknown User")"
            if let firstName = update.message?.from?.firstName, let lastName = update.message?.from?.lastName {
                name += " (\(firstName) \(lastName))"
            }
            print("\(update.message?.from?.username ?? "<Unknown Username>")\(name) tried to perform the command \(command), but failed due to insufficient permissions.")
        case .noUserID:
            sendError("Unable to retrieve the user ID of the sender.")
            print("Error: Unable to retrieve the user ID of the sender.")
        case .commandNotImplemented(let commandName):
            sendError("Error: Command not implemented yet!")
            print("Error: Command \(commandName) is not implemented yet.")
        }
    }
}
