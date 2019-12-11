//
//  BotCommand.swift
//  Notifier
//
//  Created by Jonas Frey on 17.05.19.
//

import Foundation
import TelegramBotSDK

protocol BotCommand {
    
    var context: Context { get }
    
    func run() -> Bool
}
