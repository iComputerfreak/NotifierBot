//
//  File 2.swift
//  
//
//  Created by Jonas Frey on 01.05.21.
//

import Foundation

public class PermissionHandler {
    
    public static let shared: PermissionHandler = PermissionHandler()
    
    public let configParser = ConfigParser.shared
    
    public func hasPermission(userID: Int64, permission: BotPermission) -> Bool {
        // The user permission level has to be at least the given one
        return configParser.permissionGroup(user: userID) >= permission
    }
    
}
