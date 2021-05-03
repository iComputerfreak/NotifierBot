//
//  File.swift
//  
//
//  Created by Jonas Frey on 03.05.21.
//

import Foundation
import Telegrammer

struct FetchURLCommand: Command {
    
    let name = "Fetch URL"
    let commands = ["/fetchurl"]
    let syntax = "/fetchurl <URL> \\[x y width height]"
    let description = "Takes a screenshot of the given website and settings and sends it into this chat"
    let permission = BotPermission.mod
    
    func run(update: Update, context: BotContext?) throws {
        let chatID = try update.chatID()
        let args = try update.args()
        guard args.count == 1 || args.count == 5 else {
            try showUsage(chatID)
            return
        }
        let url = args[0]
        var area: Rectangle = .zero
        if args.count == 5 {
            let x = Int(args[1])
            let y = Int(args[2])
            let width = Int(args[3])
            let height = Int(args[4])
            guard x != nil && y != nil && width != nil && height != nil else {
                try bot.sendMessage("Please enter a valid Offset and Size", to: chatID)
                return
            }
            area = Rectangle(x: x!, y: y!, width: width!, height: height!)
        }
        guard url.hasPrefix("http") else {
            try bot.sendMessage("Please enter a valid URL, starting with 'http://' or 'https://'", to: chatID)
            return
        }
        DispatchQueue.main.async {
            JFUtils.takeScreenshot(url: url, filename: "/tmp/screenshot.png", area: area)
            JFUtils.sendFile(path: "/tmp/screenshot.png", chatID: chatID)
        }
    }
}
