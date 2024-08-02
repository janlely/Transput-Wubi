//
//  AppDelegate.swift
//  AppDelegate
//
//  Created by ensan on 2021/09/06.
//

import Cocoa
import InputMethodKit
import os.log
import CoreData

let log = OSLog(subsystem: "com.ensan.inputmethod.Transput", category: "inputmethod")

// Necessary to launch this app
class NSManualApplication: NSApplication {
    private let appDelegate = AppDelegate()
//    @IBOutlet var window: NSWindow

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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String, bundleIdentifier: Bundle.main.bundleIdentifier)
        NSLog("tried connection")
//        let wd = PreferencesWindowController()
//        wd.showWindow(nil)
//        let body = """
//        {
//            "model": "qwen-turbo",
//            "messages": [
//                {
//                    "role": "system",
//                    "content": "你是一个中文到英文的翻译，你把我的所有问题中的内容都直接翻译成英文就可以"
//                },
//                {
//                    "role": "user",
//                    "content": "你是谁？"
//                }
//            ]
//        }
//        """
//        let body: [String: Any] = [
//            "model": "qwen-turbo",
//            "messages": [
//                [
//                    "role": "system",
//                    "content": "你是一个中文到英文的翻译，你把我的所有问题中的内容都直接翻译成英文就可以"
//                ],
//                [
//                    "role": "user",
//                    "content": "你是谁？"
//                ]
//            ]
//        ]
//        do {
//            // 将参数编码为JSON数据
//            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
//            NSLog("json: \(jsonData)")
//        } catch {
//            NSLog("error serialize json")
//        }
//        do {
//            
//            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
//                    // 将JSON数据转换为字符串
//            if let jsonString = String(data: jsonData, encoding: .utf8) {
//                NSLog("\(jsonString)")
//            }
//        } catch {
//            NSLog("dddd")
//        }
//        HttpClient.post(url: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
//                        parameters: body,
//                        headers: [
//                            "Content-Type": "application/json",
//                            "Authorization": "Bearer sk-1d2b610c1ffe4c79b1da58c5f5530a11"
//                        ],
//                        timeoutSeconds: 10, completion: {(res, err) in
//            NSLog("response: \(String(describing: res!["choices"]))")
//        })
    }
    
    func applicationWillTerminate(_ notification: Notification) {
    }
    
}
