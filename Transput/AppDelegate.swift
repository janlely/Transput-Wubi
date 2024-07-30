//
//  AppDelegate.swift
//  AppDelegate
//
//  Created by ensan on 2021/09/06.
//

import Cocoa
import InputMethodKit

// Necessary to launch this app
class NSManualApplication: NSApplication {
    private let appDelegate = AppDelegate()

    override init() {
        super.init()
        self.delegate = appDelegate
    }

    required init?(coder: NSCoder) {
        // No need for implementation
        fatalError("init(coder:) has not been implemented")
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var server = IMKServer()
    var transPanel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String, bundleIdentifier: Bundle.main.bundleIdentifier)
        self.transPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
                                  styleMask: [.nonactivatingPanel],
                                  backing: .buffered,
                                  defer: false)
        self.transPanel?.level = .popUpMenu
        self.transPanel?.hidesOnDeactivate = true
        self.transPanel?.isFloatingPanel = true
        self.transPanel?.contentView?.wantsLayer = true
        self.transPanel?.contentView?.layer?.backgroundColor = NSColor.red.cgColor
        NSLog("tried connection")
    }

    func applicationWillTerminate(_ notification: Notification) {
    }
}
