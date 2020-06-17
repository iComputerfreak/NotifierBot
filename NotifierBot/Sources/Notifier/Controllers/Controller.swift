//
//  File.swift
//  
//
//  Created by Jonas Frey on 15.06.20.
//

import Foundation
import TelegramBotSDK

protocol Controller {
    var router: Router { get }
    
    @discardableResult
    func process(update: Update, properties: [String: AnyObject]) throws -> Bool
}