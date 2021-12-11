//
//  JFBotError.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation

enum JFBotError: Error {
    case noMessage
    case noUserID
    // Contains the command that has been tried to execute
    case noPermissions(Command)
    // Contains the line with the malformed permission
    case malformedPermissions(String)
    // Contains the name of the command
    case commandNotImplemented(String)
    // Unable to get the message text for parsing arguments
    case noMessageText
}
