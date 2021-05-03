//
//  BotPermission.swift
//  
//
//  Created by Jonas Frey on 14.06.20.
//

import Foundation

enum BotPermission: String, Comparable, CaseIterable {
    case user = "user"
    case mod = "mod"
    case admin = "admin"
    
    static private let levels: [BotPermission: Int] = [
        .user: 0,
        .mod: 1,
        .admin: 2
    ]
    
    static func <(lhs: BotPermission, rhs: BotPermission) -> Bool {
        return levels[lhs]! < levels[rhs]!
    }
    
    static func >(lhs: BotPermission, rhs: BotPermission) -> Bool {
        return levels[lhs]! > levels[rhs]!
    }
}
