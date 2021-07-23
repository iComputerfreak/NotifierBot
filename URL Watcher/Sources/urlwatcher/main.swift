
import Foundation

/// In silent mode, telegram messages will not be sent, but instead logged to console
let silentMode: Bool = false

let fileManager = FileManager.default
/// The current working directory
let currentPath = fileManager.currentDirectoryPath
/// The telegram bot token it read from a file
let telegramBotToken = try String(contentsOfFile: "\(currentPath)/../BOT_TOKEN", encoding: .utf8)
/// The script used to send the telegram messages
let telegramScript = "\(currentPath)/../tools/telegram.sh"

// MARK: - Constant settings
/// The filename of the file containing the visual diff representation
let diffFilename = "diff.png"
/// The file containing the ncc information
let nccFilename = "ncc"
/// The file containing all urls and their settings
let urlListFile = "\(currentPath)/urls.list"
/// The file containing the user permissions
let permissionsFile = "\(currentPath)/permissions.txt"
/// The directory containing the images of the previous screenshots
let imagesDirectory = "\(currentPath)/images"
/// The threshold value the bot uses. If the NCC value is below this, a notification is triggered
let nccThreshold = 0.999
/// The duration for which a screenshot capture error has to persist for the user to be notified. Set to 0 to immediately notify on errors
let errorReportMinutes = 30

print("Starting URL Watcher...")

// If the urls.list file does not exist yet, create a new one
if !fileManager.fileExists(atPath: urlListFile) {
    fileManager.createFile(atPath: urlListFile, contents: nil)
}

// If the images directory does not exist yer, create a new one
if !fileManager.directoryExists(atPath: imagesDirectory) {
    try fileManager.createDirectory(atPath: imagesDirectory, withIntermediateDirectories: true)
}

let config = try ConfigParser.getConfig()

for entry in config {
    print("Checking \(entry.url)")
    
    let entryPath = directory(for: entry)
    
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
        
        // If there is no previous screenshot, we cannot compare anything
        guard fileManager.fileExists(atPath: oldImage) else {
            // This is a new entry
            try notifyNew(entry: entry, file: latestImage)
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
    // If the website changed
    if let ncc = try screenshotNCC(oldImage, latestImage, diffFile: tempDiff),
       ncc < nccThreshold {
        print("Possible change detected. Confirming...")
        
        // Take another screenshot to confirm its not just a one-time loading error or inconsistency
        // Delete the changed screenshot, otherwise we cannot confirm that taking the screenshot was a success
        try fileManager.removeItem(atPath: latestImage)
        
        // Re-do the whole screenshot procedure
        guard try screenshot() else {
            continue
        }
        
        if let newNCC = try screenshotNCC(oldImage, latestImage, diffFile: tempDiff),
           newNCC < nccThreshold {
            // If the second screenshot also shows changes, we notify the user
            
            // Save the temp file persistently
            let diffFile = "\(entryPath)/\(diffFilename)"
            if fileManager.fileExists(atPath: diffFile) {
                try fileManager.removeItem(atPath: diffFile)
            }
            try fileManager.moveItem(atPath: tempDiff, toPath: diffFile)
            
            // Generate detailed NCC information
            let nccFile = "\(entryPath)/\(nccFilename)"
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
        }
    }
    
    // Delete the error file if it exists, since we just successfully captured a screenshot
    let errorFile = "\(entryPath)/error"
    if fileManager.fileExists(atPath: errorFile) {
        try fileManager.removeItem(atPath: errorFile)
    }
}

print("All checks completed.")
