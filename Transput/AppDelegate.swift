//
//  AppDelegate.swift
//  AppDelegate
//
//  Created by ensan on 2021/09/06.
//

import Cocoa
import InputMethodKit


// Necessary to launch this app
//class NSManualApplication: NSApplication {
//    private let appDelegate = AppDelegate()
//
//    override init() {
//        super.init()
//        self.delegate = appDelegate
//    }
//
//    required init?(coder: NSCoder) {
//        // No need for implementation
//        fatalError("init(coder:) has not been implemented")
//    }
//}

//@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var server = IMKServer()
    var cfgWindow: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String, bundleIdentifier: Bundle.main.bundleIdentifier)
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
