
import Foundation
import Shared

/// In silent mode, telegram messages will not be sent, but instead logged to console
let silentMode: Bool = false

let fileManager = FileManager.default

/// The telegram bot token is read from a file
var telegramBotToken: String! = nil
if let t = try? String(contentsOfFile: "\(mainDirectory)/BOT_TOKEN", encoding: .utf8)
    .components(separatedBy: .newlines)
    .first {
    // Read the token from a the file
    print("Reading token from file.")
    telegramBotToken = t
} else if let t = ProcessInfo.processInfo.environment["TELEGRAM_BOT_TOKEN"] {
    // Read the token from the environment, if it exists
    print("Reading token from environment.")
    telegramBotToken = t
} else {
    print("Unable to read bot token. Please place it into the file " +
          "\(mainDirectory)/BOT_TOKEN " +
          "or provide the environment variable TELEGRAM_BOT_TOKEN")
    exit(1)
}

/// The script used to send the telegram messages
let telegramScript = "\(mainDirectory)/tools/telegram.sh"


print("Starting URL Watcher...")

// If the urls.list file does not exist yet, create a new one
if !fileManager.fileExists(atPath: kURLListFile) {
    fileManager.createFile(atPath: kURLListFile, contents: nil)
}

// If the images directory does not exist yer, create a new one
if !fileManager.directoryExists(atPath: kImagesDirectory) {
    try fileManager.createDirectory(atPath: kImagesDirectory, withIntermediateDirectories: true)
}

var config = try ConfigParser.getConfig()

do {
    
    for i in 0..<config.count {
        var entry = config[i]
        print("Checking \(entry.url)")
        
        // If the entry is muted, we skip it
        if (entry.isMuted) {
            print("Entry is still muted. Skipping...")
            continue
        }
        
        // If the entry is not muted anymore, but the unmuteDate is not reset yet,
        // we update it and continue with the execution
        if (try checkUnmute(&entry)) {
            // Save the unmuted entry
            config[i] = entry
            try ConfigParser.saveConfig(config)
        }
        
        let entryPath = SharedUtils.directory(for: entry)
        
        // Create the image directory, if it does not exist yet
        if !fileManager.directoryExists(atPath: entryPath) {
            try fileManager.createDirectory(atPath: entryPath, withIntermediateDirectories: true)
        }
        
        // At this state, the "old" and "latest" image are both old versions.
        // The latest.png image is the last screenshot made; the old.png image is the screenshot made before
        let oldImage = "\(entryPath)/old.png"
        let latestImage = "\(entryPath)/latest.png"
        
        // We now overwrite old.png with latest.png and save the new screenshot as latest.png
        // Remove the old.png image, if it exists
        if fileManager.fileExists(atPath: oldImage) {
            try fileManager.removeItem(atPath: oldImage)
        }
        // Move latest.png to old.png
        if fileManager.fileExists(atPath: latestImage) {
            try fileManager.moveItem(atPath: latestImage, toPath: oldImage)
        }
        
        /// Takes a screenshot, prepares it and checks for any errors
        /// - Returns: Whether the execution succeeded, if the execution failed, this entry should be skipped
        func screenshot() throws -> Bool {
            
            // MARK: Take Screenshot
            
            // Take a screenshot as latest.png
            let result = try takeScreenshot(ofURL: entry.url, outputPath: latestImage, delay: entry.delay, captureElement: entry.captureElement, clickElement: entry.clickElement, waitElement: entry.waitElement)
            
            // On error, roll back and skip this entry
            if result != .success || !fileManager.fileExists(atPath: latestImage) {
                try handleScreenshotError(entry: entry)
                // We have to roll back the old screenshot for next time (if there was one)
                try rollBack(oldImage, to: latestImage)
                // Skip this entry
                return false
            }
            
            // MARK: Prepare the Screenshot
            
            // Crop the screenshot
            try cropScreenshot(path: latestImage, area: entry.area)
            
            let addedPath = "\(entryPath)/.added"
            guard fileManager.fileExists(atPath: addedPath) else {
                // This is a new entry
                try notifyNew(entry: entry, file: latestImage)
                fileManager.createFile(atPath: addedPath, contents: nil)
                // Skip comparison
                return false
            }
            
            // If there is no previous screenshot, we cannot compare anything
            guard fileManager.fileExists(atPath: oldImage) else {
                // Skip comparison
                return false
            }
            
            // MARK: Check Mean Value
            
            let meanPipe = Pipe()
            try bash("convert", arguments: [latestImage, "-format", "\"%[mean]\"", "info:"], standardOutput: meanPipe)
            let meanData = meanPipe.fileHandleForReading.readDataToEndOfFile()
            let mean = String(data: meanData, encoding: .utf8)
            
            // If the image is completely black or white, we treat this as a capture error
            if mean == "0" || mean == "65535" {
                print("ERROR: Screenshot is completely blank.")
                try handleScreenshotError(entry: entry)
                try rollBack(oldImage, to: latestImage)
                // Skip the comparison
                return false
            }
            
            return true
        }
        
        // Take a screenshot
        guard try screenshot() else {
            continue
        }
        
        // MARK: Compare the Screenshots
        
        let tempDiff = "\(entryPath)/diff.temp"
        
        guard let ncc = try screenshotNCC(oldImage, latestImage, diffFile: tempDiff) else {
            print("Error checking screenshot NCC.")
            try handleScreenshotError(entry: entry)
            try rollBack(oldImage, to: latestImage)
            // Continue with the next entry
            continue
        }
        
        // If the website changed
        if ncc < kNccThreshold {
            print("Possible change detected (NCC: \(ncc)). Confirming...")
            
            // Take another screenshot to confirm its not just a one-time loading error or inconsistency
            // Delete the changed screenshot, otherwise we cannot confirm that taking the screenshot was a success
            try fileManager.removeItem(atPath: latestImage)
            
            // Re-do the whole screenshot procedure
            guard try screenshot() else {
                continue
            }
            
            guard let newNCC = try screenshotNCC(oldImage, latestImage, diffFile: tempDiff) else {
                // Error while confirming screenshot
                print("Error confirming screenshot NCC.")
                try handleScreenshotError(entry: entry)
                try rollBack(oldImage, to: latestImage)
                // Continue with the next entry
                continue
            }
            
            if newNCC < kNccThreshold {
                // If the second screenshot also shows changes, we notify the user
                print("Change confirmed. NCC: \(newNCC). Notifying user.")
                
                // Save the temp file persistently
                let diffFile = "\(entryPath)/\(kDiffFile)"
                if fileManager.fileExists(atPath: diffFile) {
                    try fileManager.removeItem(atPath: diffFile)
                }
                // The temp file could not exist, in case we only report a change due to size difference
                // (then the compare command never successfully compared the files)
                if fileManager.fileExists(atPath: tempDiff) {
                    try fileManager.moveItem(atPath: tempDiff, toPath: diffFile)
                }
                
                // Generate detailed NCC information
                let nccFile = "\(entryPath)/\(kNccFile)"
                if fileManager.fileExists(atPath: nccFile) {
                    try fileManager.removeItem(atPath: nccFile)
                }
                try bash("compare", arguments: [
                    "-verbose",
                    "-alpha", "deactivate",
                    "-metric", "NCC",
                    oldImage,
                    latestImage,
                    "/dev/null"
                ], standardOutput: FileHandle(forWritingAtPath: nccFile))
                
                // Notify the user
                try sendTelegramMessage("\(entry.name) has changed. NCC: \(ncc)\(ncc != newNCC ? ", \(newNCC)" : "")", to: Int(entry.chatID), image: latestImage)
            } else {
                print("Change not confirmed. NCC: \(newNCC)")
            }
        } else {
            print("No change detected. NCC: \(ncc)")
        }
        
        // Clean up any temp diff files
        if fileManager.fileExists(atPath: tempDiff) {
            try fileManager.removeItem(atPath: tempDiff)
        }
        
        // Delete the error file if it exists, since we just successfully captured a screenshot
        let errorFile = "\(entryPath)/.error"
        if fileManager.fileExists(atPath: errorFile) {
            try fileManager.removeItem(atPath: errorFile)
        }
        let notifiedFile = "\(entryPath)/.notified"
        if fileManager.fileExists(atPath: notifiedFile) {
            try fileManager.removeItem(atPath: notifiedFile)
        }
    }
    
} catch let error {
    print("Error while checking URLs:")
    print(error)
    // Send the error to all admins
    for admin in PermissionHandler.shared.admins {
        // No fallback if this fails
        try sendTelegramMessage("Error while trying to check URLs:\n\(error)", to: Int(admin))
    }
}

print("All checks completed.")
