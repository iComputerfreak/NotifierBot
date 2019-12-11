//
//  StatusCommand.swift
//  Notifier
//
//  Created by Jonas Frey on 17.05.19.
//

import Foundation
import TelegramBotSDK

struct StatusCommand: BotCommand {
    
    let context: Context
    
    struct ServerStatus {
        let online: Bool
        let playersOnline: Int
        let playersMax: Int
    }
    
    func run() -> Bool {
        let args = context.args.scanWords()
        
        guard args.count == 1 else {
            context.respondAsync("Please only specify one argument.")
            return true
        }
        
        let status = queryStatus(instanceName: args.first!)
        // Format the status and send the response
        let response = status.online ? "The server is online" : "The server is offline"
        
        context.respondAsync(response)
        return true
    }
    
    private func queryStatus(instanceName: String) -> ServerStatus {
        return ServerStatus(online: true, playersOnline: 1, playersMax: 10)
    }
    
}
