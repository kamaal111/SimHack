//
//  main.swift
//  
//
//  Created by Kamaal Farah on 02/04/2021.
//

import Foundation

let fileManager = FileManager.default
let jsonDecoder = JSONDecoder()

func main() {
    let start = CFAbsoluteTimeGetCurrent()
    guard let libraryDirectory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
    let contentOfLibraryFolder: [URL]
    do {
        contentOfLibraryFolder = try fileManager.contentsOfDirectory(at: libraryDirectory,
                                                                     includingPropertiesForKeys: nil,
                                                                     options: [])
    } catch {
        print(error.localizedDescription)
        return
    }
    guard let preferencesDirectory = contentOfLibraryFolder.first(where: {
        $0.absoluteString == libraryDirectory.appendingPathComponent("Preferences").absoluteString
    }) else { return }
    let contentOfPreferencesDirectory: [URL]
    do {
        contentOfPreferencesDirectory = try fileManager.contentsOfDirectory(at: preferencesDirectory,
                                                                            includingPropertiesForKeys: nil,
                                                                            options: [])
    } catch {
        print(error.localizedDescription)
        return
    }

    guard let iPhoneSimulatorConfigurationsFile = contentOfPreferencesDirectory.first(where: {
        $0.absoluteString == preferencesDirectory.appendingPathComponent("com.apple.iphonesimulator.plist").absoluteString
    }) else { return }
    guard let iPhoneSimulatorConfigurationsDict = NSMutableDictionary(contentsOfFile: iPhoneSimulatorConfigurationsFile.path)
    else { return }
    guard let devicePreferencesDict = iPhoneSimulatorConfigurationsDict.object(forKey: "DevicePreferences") as? NSMutableDictionary
    else { return }
    for (iPhoneIdentifier, devicePreferencesValue) in devicePreferencesDict {
        if let devicePreferencesValueDict = devicePreferencesValue as? NSMutableDictionary {
            if let connectedHardwareKeyboard = devicePreferencesValueDict.object(forKey: "ConnectHardwareKeyboard") as? Bool {
                if connectedHardwareKeyboard {
                    devicePreferencesValueDict.setValue(false, forKey: "ConnectHardwareKeyboard")
                    if let identifier = iPhoneIdentifier as? String {
                        devicePreferencesDict.setValue(devicePreferencesValueDict, forKey: identifier)
                    }
                }
            }
        }
    }

    iPhoneSimulatorConfigurationsDict.setValue(devicePreferencesDict, forKey: "DevicePreferences")
    iPhoneSimulatorConfigurationsDict.write(toFile: iPhoneSimulatorConfigurationsFile.path, atomically: true)

    do {
        try zShell("plutil -convert binary1 \(iPhoneSimulatorConfigurationsFile.path)")
    } catch {
        print(error.localizedDescription)
        return
    }

//    do {
//        let simulators = try zShell("xcrun simctl list")
//        print(simulators)
//    } catch {
//        print(error.localizedDescription)
//        return
//    }

    let diff = CFAbsoluteTimeGetCurrent() - start
    print("Took \(diff) seconds ✨")
}

@discardableResult
func zShell(_ command: String, at executionLocation: String? = nil) throws -> String {
    try shell("/bin/sh", command, at: executionLocation)
}

enum ShellErrors: Error {
    case failed

    var localizedDescription: String {
        switch self {
        case .failed:
            return "Shell command failed to execute"
        }
    }
}

func shell(_ launchPath: String, _ command: String, at executionLocation: String? = nil) throws -> String {
    let task = Process()
    var commandToUse: String
    if let executionLocation = executionLocation {
        commandToUse = "cd \(executionLocation) && \(command)"
    } else {
        commandToUse = command
    }
    task.arguments = ["-c", commandToUse]
    task.launchPath = launchPath

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    task.waitUntilExit()

    if task.terminationStatus != 0 {
        throw ShellErrors.failed
    }
    return output
}

main()
