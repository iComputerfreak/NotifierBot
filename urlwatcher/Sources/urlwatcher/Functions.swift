//
//  File.swift
//  
//
//  Created by Jonas Frey on 22.07.21.
//

import Foundation
import Shared

func takeScreenshot(ofURL url: String, outputPath: String, delay: Int? = nil, captureElement: String? = nil,
                    clickElement: String? = nil, waitElement: String? = nil) throws -> BashResult {
    let screenshotCommand = "capture-website"
    var arguments = [
        url,
        "--output=\"\(outputPath)\"",
        "--overwrite",
        "--full-page",
        "--timeout=30", // decrease timeout to prevent waiting for elements that are not there anymore
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
        "-crop", "\(width)x\(height)+\(x)+\(y)",
        output ?? path
    ])
}

func imageSize(path: String) throws -> (width: Int, height: Int) {
    let pipe = Pipe()
    // Sample Output:
    // PNG image data, 2938 x 16300, 8-bit/color RGBA, non-interlaced
    try bash("file", arguments: [path, "-b"], standardOutput: pipe)
    
    let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let outputString = String(data: outputData, encoding: .utf8) else {
        return (0, 0)
    }
    
    let components = outputString.components(separatedBy: ", ")
    guard components.count >= 2 else {
        return (0, 0)
    }
    
    let sizeComponents = components[1].components(separatedBy: "x").map({ $0.trimmingCharacters(in: .whitespaces) })
    guard sizeComponents.count == 2 else {
        return (0, 0)
    }
    guard let width = Int(sizeComponents[0]), let height = Int(sizeComponents[1]) else {
        return (0, 0)
    }
    
    return (width, height)
}

func sendTelegramMessage(_ message: String, to chatID: Int, image: String? = nil, file: String? = nil) throws {
    var arguments: [String] = [
        "-t", telegramBotToken!,
        "-c", "\(chatID)"
    ]
    if let image = image {
        // https://core.telegram.org/bots/api#sendphoto
        // > The photo must be at most 10 MB in size.
        // > The photo's width and height must not exceed 10000 in total.
        // > Width and height ratio must be at most 20.
        // If any of these requirements are not met, send the image as a file
        let attr = try fileManager.attributesOfItem(atPath: image)
        // File size in MB
        var fileSize = attr[.size] as? Float ?? 0
        fileSize /= 1024 * 1024
        // Make sure the file is under the 10 MB limit (plus 0.1 MB extra)
        guard fileSize < 9.9 else {
            try sendTelegramMessage(message, to: chatID, file: image)
            return
        }
        
        let imSize = try imageSize(path: image)
        guard imSize.width <= 10_000 && imSize.height <= 10_000 else {
            try sendTelegramMessage(message, to: chatID, file: image)
            return
        }
        
        if imSize.width != imSize.height {
            // Width and height ratio = max / min
            guard max(imSize.width, imSize.height) / min(imSize.width, imSize.height) <= 20 else {
                try sendTelegramMessage(message, to: chatID, file: image)
                return
            }
        }
        
        // If all requirements are met, we can send the image
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
    let errorFile = "\(directory(for: entry))/.error"
    // If the errorReportMinutes are not set, we immediately notify the user
    guard kErrorReportDuration > 0 else {
        try notifyError(entry: entry)
        return
    }
    
    // Before we notify the user, we check if the error hast persisted for the last few minutes to avoid notifying the
    // user at single screenshot errors
    // We do this, by checking for a file 'error' and its creation date to see when the error first appeared.
    // This file should be deleted on the next successful capture
    if !fileManager.fileExists(atPath: errorFile) {
        print("Creating error file at \(errorFile)")
        // If the error file does not exist yet, create a new one and return
        let content = ISO8601DateFormatter().string(from: Date())
        try content.write(toFile: errorFile, atomically: true, encoding: .utf8)
        return
    }
    
    // If an error file already exists, read the creation date from the file's contents
    print("Error file already exists")
    if fileManager.fileExists(atPath: errorFile) {
       let errorContents = try String(contentsOfFile: errorFile)
        print("Creation date: \(errorContents)")
        guard let creationDate = ISO8601DateFormatter().date(from: errorContents) else {
            throw JFUrlwatcherError.noErrorCreationDate(entry)
        }
        if creationDate.distance(to: Date()) >= kErrorReportDuration {
            // Notify the user that an error persisted for the last `errorReportTime` seconds
            try notifyError(entry: entry)
        }
    }
}

func notifyError(entry: URLEntry) throws {
    if entry.isMuted {
        print("Error taking screenshot, but entry is muted.")
        return
    }
    print("Error taking screenshot. Notifying user...")
    // TODO: Replace with DateComponentsFormatter when available on Linux
    let f = SharedUtils.DummyFormatter(fullUnits: true)
    let durationString = f.string(from: kErrorReportDuration) ?? "some time"
    try sendTelegramMessage("The entry '\(entry.name)' failed to capture a screenshot for " +
                            "\(durationString.isEmpty ? "some time" : "at least \(durationString)").",
                            to: Int(entry.chatID))
}

func notifyUnmuted(entry: URLEntry) throws {
    print("Entry unmuted. Notifying user...")
    try sendTelegramMessage("The entry '\(entry.name)' is no longer muted.", to: Int(entry.chatID))
}

func notifyNew(entry: URLEntry, file: String) throws {
    if entry.isMuted {
        print("New entry, but entry is muted.")
        return
    }
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
    
    let nccData = nccPipe.fileHandleForReading.readDataToEndOfFile()
    guard let nccString = String(data: nccData, encoding: .utf8) else {
        return nil
    }
    
    // If the images are different-sized, we don't need to treat this as an error.
    // Instead, we just notify the user about it by setting the NCC to 0
    if nccString.contains("compare: image widths or heights differ") {
        return 0
    }
    
    // The compare command returns 0, if the images are similar, 1 if they are dissimilar and something else on an error
    // The error case of different sizes was already handled by the above statement
    if case .failure(let code) = result,
       code != 1 && code != 0 {
        return nil
    }
    
    return Double(nccString)
}

func checkUnmute(_ entry: inout URLEntry) throws -> Bool {
    // Check if entry is to be unmuted and unmute it
    if !entry.isMuted && entry.unmuteDate != nil {
        entry.unmuteDate = nil
        try notifyUnmuted(entry: entry)
        return true
    }
    return false
}
