//
//  BotCommand.swift
//  Notifier
//
//  Created by Jonas Frey on 17.05.19.
//

import Foundation
import TelegramBotSDK

protocol BotCommand {
    static func runCommand(_ context: Context) -> Bool
}
