//
//  File.swift
//  
//
//  Created by Jonas Frey on 22.07.21.
//

import Foundation

func takeScreenshot(ofURL url: String, outputPath: String, delay: Int? = nil, captureElement: String? = nil, clickElement: String? = nil, waitElement: String? = nil) throws -> BashResult {
    let screenshotCommand = "capture-website"
    var arguments = [
        url,
        "--output=\"\(outputPath)\"",
        "--overwrite",
        "--full-page",
        "--user-agent=\"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.50 Safari/537.36\""
    ]
    if let delay = delay, delay > 0 {
        arguments.append("--delay=\(delay)")
    }
    if let captureElement = captureElement, !captureElement.isEmpty {
        arguments.append("--element=\"\(captureElement)\"")
    }
    if let clickElement = clickElement, !clickElement.isEmpty {
        arguments.append("--click-element=\"\(clickElement)\"")
    }
    if let waitElement = waitElement, !waitElement.isEmpty {
        arguments.append("--wait-for-element=\"\(waitElement)\"")
    }
    
    // Take the screenshot
    var result = try bash(screenshotCommand, arguments: arguments)
    
    // If screenshot creation failed, retake the screenshot once
    if result != .success {
        print("Error taking screenshot for \(url). Retrying...")
        // Wait 2 seconds before taking the screenshot again
        sleep(2)
        result = try bash(screenshotCommand, arguments: arguments)
    }
    
    // Return the final result
    return result
}

@discardableResult
func cropScreenshot(path: String, output: String? = nil, area: Rectangle) throws -> BashResult {
    return try cropScreenshot(path: path, output: output, x: area.x, y: area.y, width: area.width, height: area.height)
}

@discardableResult
func cropScreenshot(path: String, output: String? = nil, x: Int, y: Int, width: Int, height: Int) throws -> BashResult {
    // Cropping to zero width or height does not make sense
    guard width > 0 && height > 0 else {
        return .argumentError
    }
    
    return try bash("convert", arguments: [
        path,
        "-crop", "\"\(width)x\(height)+\(x)+\(y)\"",
        output ?? path
    ])
}

func sendTelegramMessage(_ message: String, to chatID: Int, image: String? = nil, file: String? = nil) throws {
    var arguments: [String] = [
        "-t", telegramBotToken,
        "-c", "\(chatID)"
    ]
    if let image = image {
        arguments.append(contentsOf: ["-i", image])
    }
    if let file = file {
        arguments.append(contentsOf: ["-f", file])
    }
    arguments.append(message)
    
    if silentMode {
        print("[TELEGRAM] \(arguments.joined(separator: " "))")
    } else {
        try bash(telegramScript, arguments: arguments, noEnv: true)
    }
}

func handleScreenshotError(entry: URLEntry) throws {
    print("Handling error.")
    let errorFile = "\(directory(for: entry))/error"
    // If the errorReportMinutes are not set, we immediately notify the user
    guard errorReportMinutes > 0 else {
        try notifyError(entry: entry)
        return
    }
    
    // Before we notify the user, we check if the error hast persisted for the last few minutes to avoid notifying the user at single screenshot errors
    // We do this, by checking for a file 'error' and its creation date to see when the error first appeared.
    // This file should be deleted on the next successful capture
    if !fileManager.fileExists(atPath: errorFile) {
        // If the error file does not exist yet, create a new one and return
        fileManager.createFile(atPath: errorFile, contents: nil)
        return
    }
    
    // If an error file already exists, get the attributes and check the creation date
    if fileManager.fileExists(atPath: errorFile),
       let creationDate = try fileManager.attributesOfItem(atPath: errorFile)[.creationDate] as? Date,
       creationDate.distance(to: Date()) >= Double(errorReportMinutes * 60) {
        // Notify the user that an error persisted for the last `errorReportTime` seconds
        try notifyError(entry: entry)
    }
}

func notifyError(entry: URLEntry) throws {
    print("Error taking screenshot. Notifying user...")
    try sendTelegramMessage("The entry '\(entry.name)' failed to capture a screenshot for the last \(errorReportMinutes) minutes.", to: Int(entry.chatID))
    
}

func notifyNew(entry: URLEntry, file: String) throws {
    print("New entry: \(entry)")
    try sendTelegramMessage("Added '\(entry.name)'", to: Int(entry.chatID), file: file)
}

func rollBack(_ oldImage: String, to latestImage: String) throws {
    if fileManager.fileExists(atPath: oldImage) {
        if fileManager.fileExists(atPath: latestImage) {
            try fileManager.removeItem(atPath: latestImage)
        }
        try fileManager.moveItem(atPath: oldImage, toPath: latestImage)
    }
}

// Calculates the normalized cross-correlation
func screenshotNCC(_ oldImage: String, _ latestImage: String, diffFile: String) throws -> Double? {
    let nccPipe = Pipe()
    let result = try bash("compare", arguments: [
        "-quiet",
        "-alpha", "deactivate",
        "-metric", "NCC",
        oldImage,
        latestImage,
        diffFile
    ], standardOutput: nccPipe, standardError: nccPipe)
    
    // The compare command returns 0, if the images are similar, 1 if they are dissimilar and something else on an error
    if case .failure(let code) = result,
       code != 1 && code != 0 {
        return nil
    }
    
    let nccData = nccPipe.fileHandleForReading.readDataToEndOfFile()
    guard let nccString = String(data: nccData, encoding: .utf8) else {
        return nil
    }
    return Double(nccString)
}
