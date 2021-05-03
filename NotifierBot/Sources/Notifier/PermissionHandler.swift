//
//  File 2.swift
//  
//
//  Created by Jonas Frey on 01.05.21.
//

import Foundation

class PermissionHandler {
    
    static let shared: PermissionHandler = PermissionHandler()
    
    let configParser = ConfigParser.shared
    
    func hasPermission(userID: Int64, permission: BotPermission) -> Bool {
        // The user permission level has to be at least the given one
        return configParser.permissionGroup(user: userID) >= permission
    }
    
}
