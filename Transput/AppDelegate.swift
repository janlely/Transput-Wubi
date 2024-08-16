//
//  AppDelegate.swift
//  AppDelegate
//
//  Created by jin junjie on 2024/7/25.
//

import Cocoa
import InputMethodKit


class AppDelegate: NSObject, NSApplicationDelegate {
    var server = IMKServer()
    var cfgWindow: NSWindow!
    var candidatesWindow: IMKCandidates!

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String, bundleIdentifier: Bundle.main.bundleIdentifier)
        self.candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel)
        NSLog("tried connection")
        for window in NSApplication.shared.windows {
            if window.title == "输入法配置" {
                self.cfgWindow = window
            }
        }

    }
    
    func applicationWillTerminate(_ notification: Notification) {
    }

}
