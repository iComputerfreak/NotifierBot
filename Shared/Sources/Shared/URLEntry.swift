//
//  URLEntry.swift
//  
//
//  Created by Jonas Frey on 11.12.21.
//

import Foundation

public struct URLEntry {
    public var name: String
    public var url: String
    public var area: Rectangle
    public var chatID: Int64
    public var delay: Int
    public var captureElement: String
    public var clickElement: String
    public var waitElement: String
    public var unmuteDate: Date?
    public var isMuted: Bool
    
    public init(name: String, url: String, area: Rectangle, chatID: Int64, delay: Int = 0,
                captureElement: String = "", clickElement: String = "", waitElement: String = "", unmuteDate: Date? = nil) {
        self.name = name
        self.url = url
        self.area = area
        self.chatID = chatID
        self.delay = delay
        self.captureElement = captureElement
        self.clickElement = clickElement
        self.waitElement = waitElement
        self.unmuteDate = unmuteDate
        self.isMuted = {
            guard let unmuteDate = unmuteDate else {
                return false
            }
            return unmuteDate < Date()
        }()
    }
}

public struct Rectangle {
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int
    
    public static let zero = Rectangle(x: 0, y: 0, width: 0, height: 0)
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
