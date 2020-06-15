//
//  File.swift
//  
//
//  Created by Jonas Frey on 15.06.20.
//

import Foundation
import TelegramBotSDK

class PermissionController: Controller {
    
    var configParser = ConfigParser()
    var router = Router(bot: bot)
    
    init(mainRouter: Router) {
        for command in JFCommand.allCommands {
            router[command] = { context in
                // Check if the user has the required permissions
                if !self.hasPermission(context, command) {
                    // If the user does not have the required permissions, abort matching
                    throw BotError.noPermissions(command)
                }
                // Otherwise return false, to continue matching with the command router
                return false
            }
        }
        // If the permission check detected insufficient permissions, it stopped matching, otherwise, continue with command execution
        router.unmatched = mainRouter.handler
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
