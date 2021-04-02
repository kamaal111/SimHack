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
    guard let libraryDirectory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
    let contentOfLibraryFolder: [URL]
    do {
        contentOfLibraryFolder = try fileManager.contentsOfDirectory(at: libraryDirectory,
                                                                     includingPropertiesForKeys: nil,
                                                                     options: [])
    } catch {
        print(error)
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
        print(error)
        return
    }

    guard let iPhoneSimulatorConfigurationsFile = contentOfPreferencesDirectory.first(where: {
        $0.absoluteString == preferencesDirectory.appendingPathComponent("com.apple.iphonesimulator.plist").absoluteString
    }) else { return }
    guard let iPhoneSimulatorConfigurationsXML = fileManager.contents(atPath: iPhoneSimulatorConfigurationsFile.path)
    else { return }
    var propertyListSerialization =  PropertyListSerialization.PropertyListFormat.xml
    var iPhoneSimulatorConfigurationsDict: [String: AnyObject]
    do {
        iPhoneSimulatorConfigurationsDict = try PropertyListSerialization
            .propertyList(from: iPhoneSimulatorConfigurationsXML,
                          options: .mutableContainersAndLeaves,
                          format: &propertyListSerialization) as! [String:AnyObject]
    } catch {
        print(error)
        return
    }

    guard var devicePreferences = iPhoneSimulatorConfigurationsDict["DevicePreferences"] as? [String: [String: Any]] else { return }
    for (iPhoneSimulatorIdentifier, iPhoneSimulatorConfiguration) in devicePreferences {
        if let connectedHardwareKeyboard = iPhoneSimulatorConfiguration["ConnectHardwareKeyboard"] as? Bool {
            if connectedHardwareKeyboard {
                devicePreferences[iPhoneSimulatorIdentifier]?["ConnectHardwareKeyboard"] = 0
            }
        }
    }
    iPhoneSimulatorConfigurationsDict["DevicePreferences"] = devicePreferences as AnyObject?
    print("exit 0")
}

main()
