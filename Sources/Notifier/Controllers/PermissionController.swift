//
//  File.swift
//  
//
//  Created by Jonas Frey on 15.06.20.
//

import Foundation
import TelegramBotSDK

class PermissionController: Controller {
    
    var router = Router(bot: bot)
    
    init() {
        // Don't warn when arguments got ignored
        router.partialMatch = { _ in true }
        for command in JFCommand.allCommands {
            router[command, .slashRequired] = { context in
                // Check if the user has the required permissions
                if !self.hasPermission(context, command) {
                    // If the user does not have the required permissions, throw an error
                    throw BotError.noPermissions(command)
                }
                // In any case, stop matching to prevent matching other commands (e.g. /list also matches /listall)
                return true
            }
        }
    }
    
    @discardableResult
    func process(update: Update, properties: [String: AnyObject] = [:]) throws -> Bool {
        return try router.process(update: update, properties: properties)
    }
    
    private func hasPermission(_ context: Context, _ command: JFCommand) -> Bool {
        guard let userID = context.fromId else {
            return false
        }
        let group = configParser.permissionGroup(user: userID)
        // User has to have at least the level required
        return group >= command.permission
    }
    
}
