//
//  KeyboardMoniter.swift
//  Transput
//
//  Created by jin junjie on 2024/8/1.
//

import Foundation

import IOKit.hid
import InputMethodKit
import os.log

class KeyboardMonitor {
    private var manager: IOHIDManager?

    func startMonitoring() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        let matching = IOServiceMatching(kIOHIDDeviceKey)
        IOHIDManagerSetDeviceMatching(manager!, matching)

        IOHIDManagerRegisterInputValueCallback(manager!, { context, result, sender, value in
            let usagePage = IOHIDElementGetUsagePage(IOHIDValueGetElement(value))
            let usage = IOHIDElementGetUsage(IOHIDValueGetElement(value))
            
            if usagePage == 0x07 && usage == 0x39 { // Caps Lock key
                os_log(.info, log: log, "切换到英文输入法")
                // 实现切换到上一个输入法的逻辑
                let inputSource = TISCopyInputSourceForLanguage("en" as CFString).takeRetainedValue()
                TISSelectInputSource(inputSource)
            }
        }, nil)

        IOHIDManagerScheduleWithRunLoop(manager!, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager!, IOOptionBits(kIOHIDOptionsTypeNone))
    }
}
