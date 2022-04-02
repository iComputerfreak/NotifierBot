//
//  JFLiterals.swift
//  
//
//  Created by Jonas Frey on 11.12.21.
//

import Foundation

public let mainDirectory: String = {
    // Save the directory, the program is executed in for the shell scripts later
    var components = Bundle.main.executablePath?
    // Remove the filename, only use the directory
        // We don't want to remove a preceding `/`
        .split(separator: "/", omittingEmptySubsequences: false)
        .map(String.init)
    while components?.last?.isEmpty ?? false {
        components?.removeLast()
    }
    // Remove the filename
    components?.removeLast()
    // Remove the urlwatcher directory (in case we are in it right now)
    if components?.last == "urlwatcher" {
        components?.removeLast()
    }
    var mainDirectory = components?
        .joined(separator: "/")
    if !(ProcessInfo.processInfo.environment["NOTIFIER_BOT_DEBUG"]?.isEmpty ?? true) {
        // If the debug variable is set, we use the working directory as mainDirectory
        // (e.g. when debugging in Xcode)
        mainDirectory = FileManager.default.currentDirectoryPath
        print("Using debug directory as main: \(mainDirectory ?? "nil")")
    }
    print("Installation Directory: \(mainDirectory ?? "nil")")
    
    // If no install directory could be constructed:
    guard mainDirectory != nil else {
        print("ERROR: Unable to read the installation directory!")
        exit(1)
    }
    
    return mainDirectory!
}()

/* ************ */
/* BOT SETTINGS */
/* ************ */

/// The file containing the user permissions
public let kPermissionsFile = "\(mainDirectory)/permissions.txt"
/// The file containing all urls and their settings
public let kURLListFile = "\(mainDirectory)/urlwatcher/urls.list"
/// The directory containing the images of the previous screenshots
public let kImagesDirectory = "\(mainDirectory)/urlwatcher/images"
/// The url_watcher.sh script that actually performs the monitoring
public let kUrlwatchTool = "\(mainDirectory)/urlwatcher/urlwatcher"
/// The python screenshot script that takes the screenshot
public let kScreenshotScript = "\(mainDirectory)/tools/screenshot.sh"
/// The telegram.sh script from here: https://github.com/fabianonline/telegram.sh
public let kTelegramScript = "\(mainDirectory)/tools/telegram.sh"

// You probably don't need to change these:
/// The python3 binary
public let kPythonPath = "/usr/bin/python3"
/// The convert binary from the imagemagick package
public let kConvertPath = "/usr/bin/convert"

/// The file containing the ncc information
public let kNccFile = "ncc"
/// The filename of the file containing the visual diff representation
public let kDiffFile = "diff.png"

/// The threshold value the bot uses. If the NCC value is below this, a notification is triggered
public let kNccThreshold = 0.999
/// The duration for which a screenshot capture error has to persist for the user to be notified. Set to 0 to immediately notify on errors
public let kErrorReportDuration: TimeInterval = 120 * 60 // 2 hours
