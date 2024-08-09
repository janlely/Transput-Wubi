//
//  TransputInputController.swift
//  Transput
//
//  Created by jin junjie on 2024/7/25.
//

import Cocoa
import InputMethodKit
import os.log


@objc(TransputInputController)
class TransputInputController: IMKInputController {
    
    
    private var candidatesWindow: IMKCandidates
    private var transPanel: NSPanel!
    private var inputModePanel: NSPanel!
    private var inputModelabel: NSTextField!
    private var transBtn: NSButton!
    private var transRect: (x: CGFloat, y: CGFloat, height: CGFloat) = (0, 0, 0)
    private var inputHanlder: InputHandler = InputHandler()
    private var shiftIsDown: Bool = false
    private var shiftPushedAlone: Bool = false

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        os_log(.info, log: log, "init")
        self.candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel)
        super.init(server: server, delegate: delegate, client: inputClient)
        initTransPanel()
        initInputModePanel()
        
        os_log(.info, log: log, "loading wubi: \(Date().timeIntervalSince1970)")
        self.inputHanlder.loadDict()
        os_log(.info, log: log, "wubi loaded: \(Date().timeIntervalSince1970)")
    }
    
    func initTransPanel() {
        os_log(.info, log: log, "初始化翻译面板")
        transPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 100, height: 26),
                            styleMask: [.nonactivatingPanel],
                            backing: .buffered,
                            defer: false)

        // 设置窗口级别
        transPanel.level = .popUpMenu
        // 设置窗口行为
        transPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        transPanel.isFloatingPanel = true
        // 确保panel不会成为key window
        transPanel.becomesKeyOnlyIfNeeded = true
        // 允许panel接收鼠标事件，但不成为key window
        transPanel.acceptsMouseMovedEvents = true
        // 设置内容视图
        transPanel.contentView?.wantsLayer = true
        transPanel.contentView?.layer?.cornerRadius = 10

        transPanel.contentView?.layer?.backgroundColor = NSColor.red.cgColor

        // 使用 Core Animation 添加动画
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 0.5
        transPanel.contentView?.layer?.add(animation, forKey: "fadeIn")
        
        
        transBtn = NSButton(title: "翻译成英语", target: self, action: #selector(buttonClicked))
        transBtn.isBordered = false
        transBtn.layer?.backgroundColor = NSColor.white.cgColor
        transPanel.contentView?.addSubview(transBtn)
        
        
        transBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            transBtn.topAnchor.constraint(equalTo: transPanel.contentView!.topAnchor),
            transBtn.leadingAnchor.constraint(equalTo: transPanel.contentView!.leadingAnchor),
            transBtn.trailingAnchor.constraint(equalTo: transPanel.contentView!.trailingAnchor),
            transBtn.bottomAnchor.constraint(equalTo: transPanel.contentView!.bottomAnchor)
        ])
    }
    
    func initInputModePanel() {
        os_log(.info, log: log, "初始化中英切换面板")
        inputModePanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 28, height: 28),
                            styleMask: [.nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        
        inputModelabel = NSTextField(frame: NSRect.zero)
        inputModelabel.isEditable = false
        inputModelabel.font = NSFont.systemFont(ofSize: 16)
        inputModelabel.backgroundColor = NSColor.white
        inputModelabel.textColor = NSColor.black

        inputModePanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        inputModePanel.isFloatingPanel = true
        // 确保panel不会成为key window
        inputModePanel.becomesKeyOnlyIfNeeded = true
        inputModePanel.level = .popUpMenu
        inputModePanel.contentView?.wantsLayer = true
        inputModePanel.contentView?.layer?.backgroundColor = NSColor.gray.cgColor
        inputModePanel.contentView?.addSubview(inputModelabel)

        inputModelabel.centerXAnchor.constraint(equalTo: inputModePanel.contentView!.centerXAnchor).isActive = true
        inputModelabel.centerYAnchor.constraint(equalTo: inputModePanel.contentView!.centerYAnchor).isActive = true
        inputModelabel.frame.size = NSMakeSize(26, 26)
    }

    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        
//        let modifiers = event.modifierFlags
//        let changes = lastModifiers.symmetricDifference(modifiers)

        os_log(.info, log: log, "handle,进行输入处理程序")
        if !(sender is IMKTextInput) {
            os_log(.error, log: log, "sender不是IMKTextInput")
            return false
        }
        
        switch event.type {
        case .flagsChanged:
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            //假设shift是单独被按下的
            if modifiers.contains(.shift) && !modifiers.contains(.option)
                && !modifiers.contains(.command) && !modifiers.contains(.control) {
                os_log(.info, log: log, "shift按下")
                shiftIsDown = true
                shiftPushedAlone = true
                return true
            }
            
            if modifiers.rawValue == 0 {
                //shift键抬起之前没有其他keyDown事件，说明shift是单独被按下的
                if shiftPushedAlone && shiftIsDown {
                    os_log(.info, log: log, "shift抬起，切换中/英文")
                    self.switchInputMode()
                }
                shiftIsDown = false
                return true
            }
            return false
        case .keyDown:
            return handlerKeyDown(event)
        default:
            return false
        }
        
    }
    
    func handlerKeyDown(_ event: NSEvent!) -> Bool {
        
        os_log(.info, log: log, "handle,开始进行输入处理")

        //忽略所有的command, option, control组合键
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // 如果有任何修饰键被按下，就忽略这个事件
        if modifierFlags.contains(.command) ||
           modifierFlags.contains(.option) ||
            modifierFlags.contains(.control) {
            os_log(.info, log: log, "忽略组合键")
            return false
        }
        
        //说明shift不是单独按下的
        if modifierFlags.contains(.shift) {
            shiftPushedAlone = false
        }

        switch event.keyCode {
        case 51: //backspace
            os_log(.info, log: log, "handler,处理退格")
            return handlerInput(.backspace)
        case 49: //Space
            os_log(.info, log: log, "handler,处理空格")
            return handlerInput(.space)
        case 36: //Enter
            os_log(.info, log: log, "handler,处理回车")
            return handlerInput(.enter)
        default:
            os_log(.info, log: log, "handler,处理其他字符")
            guard let text = event.characters,
                  text.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0.isPunctuation || $0.isSymbol) }) else {
                os_log(.info, log: log, "不支持的按键: %{public}d", event.keyCode)
                return false
            }
            //跳过非小写字线开头的输入
            guard let ch = text.first else {
                os_log(.info, log: log, "不支持的按键2: %{public}d", event.keyCode)
                return false
            }
            let char = convertPunctuation(ch)
            if char.isLowercase {
                return handlerInput(.lower(char: char))
            }
            if char.isNumber {
                return handlerInput(.number(num: char))
            }
            return handlerInput(.other(char: char))
        }
    }
    
    func handlerInput(_ charType: CharType) -> Bool {
        //如果非AI模式，并且当前是英文状态，则直接提交之前的输入，并返回
        if !ConfigModel.shared.useAITrans && self.inputHanlder.isEnMode {
            self.commitText(self.inputHanlder.getCompsingText())
            return false
        }
        let inputResult = self.inputHanlder.handlerInput(charType)
        let content = self.inputHanlder.getCompsingText()
        switch inputResult {
        case .commit:
            self.commitText(content)
            self.inputHanlder.clear()
            return true
        case .conditionalCommit:
            if ConfigModel.shared.useAITrans {
                self.setMarkedText(content)
            } else {
                self.commitText(content)
            }
            return true
        case .continute:
            self.setMarkedText(content)
            return true
        case .ignore:
            return false
        }
    }
    
    
    override func candidates(_ sender: Any!) -> [Any]! {
        os_log(.info, log: log, "生成候选词")
        return self.inputHanlder.makeCadidates()
    }

    override func candidateSelected(_ candidateString: NSAttributedString!) {
        os_log(.info, log: log, "选择候选词: %s", candidateString.string)
        let content = self.inputHanlder.select(candidateString.string)
        os_log(.info, log: log, "标记用户输入: %s", content)
        hideCadidatesWindow()
        setMarkedText(content)
    }
    
    
    
    func setMarkedText(_ text: String) {
        os_log(.info, log: log, "marked text: #%{public}s#", text)
        self.client().setMarkedText(text, selectionRange: .notFound, replacementRange: .notFound)
        self.candidatesWindow.update()
        if !self.inputHanlder.hasCadidates() {
            os_log(.info, log: log, "候选词列表为空")
            hideCadidatesWindow()
            if text.containsChineseCharacters {
                //获取标记文本末尾的位置
                showPanel()
            } else {
                hideTransPanel()
            }
            return
        }
        hideTransPanel()
        showCadidatesWindow()
    }
    
    @objc func buttonClicked(_ sender: NSButton) {
        os_log(.info, log: log, "点击翻译")
        let content = self.inputHanlder.getCompsingText()
        // 处理按钮点击事件
        switch ConfigModel.shared.modelType {
        case .tongyi:
            TongyiQianWen(apiKey: ConfigModel.shared.apiKey).translate(content, completion: {response in
                self.commitText(response)
            }, defaultHandler: { () in self.commitText(content) })
        default:
            os_log(.info, log: log, "未知模型，提交当前内容")
            self.commitText(content)
        }
    }
    
    
    func showCadidatesWindow() {
        if Thread.isMainThread {
            self.candidatesWindow.show()
        } else {
            DispatchQueue.main.async {
                self.candidatesWindow.show()
            }
        }
    }
    
    func hideCadidatesWindow() {
        if Thread.isMainThread {
            self.candidatesWindow.hide()
        } else {
            DispatchQueue.main.async {
                self.candidatesWindow.hide()
            }
        }
    }

    
    func showPanel() {
        if Thread.isMainThread {
            doShowPanel()
        } else {
            DispatchQueue.main.async {
                self.doShowPanel()
            }
        }
    }
    
    func findPosition() -> NSRect {
        var inputPos = NSRect()
        let attr = self.client().attributes(forCharacterIndex: 0, lineHeightRectangle: &inputPos)
        var heigthOffset: CGFloat = 26
        if let lineHeight = attr?["IMKLineHeight"] as? NSNumber {
            heigthOffset = CGFloat(lineHeight.floatValue)
        }
        if let screenFrame = NSScreen.main {
            if inputPos.minY > screenFrame.frame.width / 2 {
                inputPos.origin.y = inputPos.minY - heigthOffset
            } else {
                inputPos.origin.y = inputPos.minY + heigthOffset
            }
        }
        os_log(.info, log: log, "显示翻译按钮, x: %{public}.1f, y: %{public}.1f, width: %{public}.1f, height: %{public}.1f",
               inputPos.minX, inputPos.minY, 100, 26)
        return inputPos
    }
    
    
    func doShowPanel() {
        if !ConfigModel.shared.useAITrans {
            return
        }
        let inputPos = findPosition()
        os_log(.info, log: log, "显示翻译按钮, x: %{public}.1f, y: %{public}.1f, width: %{public}.1f, height: %{public}.1f",
               inputPos.minX, inputPos.minY, 100, 26)
        self.transPanel.setFrame(inputPos, display: false)
        self.transPanel.orderFront(nil)
    }
    
    
    func hideTransPanel() {
        if !ConfigModel.shared.useAITrans {
            return
        }
        os_log(.info, log: log, "隐藏翻译按钮")
        if Thread.isMainThread {
            self.transPanel.orderOut(nil)
        } else {
            // 当前线程不是主线程，需要在主线程上执行 orderOut
            DispatchQueue.main.async {
                self.transPanel.orderOut(nil)
            }
        }
    }
    
    
    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        os_log(.info, log: log, "启用输入法")
        hideTransPanel()
        self.inputHanlder.clear()
        hidePalettes()
    }
    
    override func deactivateServer(_ sender: Any!) {
        os_log(.info, log: log, "停用输入法, sender: %{public}s", sender.debugDescription)
        commitText(self.inputHanlder.getCompsingText())
//        hideCadidatesWindow()
        hideTransPanel()
        hidePalettes()
    }
    
    func commitText(_ content: String) {
        self.hideTransPanel()
        self.client()?.insertText(content, replacementRange: .empty)
        self.inputHanlder.clear()
        hideCadidatesWindow()
    }
    
    
    override func menu() -> NSMenu! {
        let settings = NSMenuItem(title: NSLocalizedString("Settings", comment: "Menu item"), action: #selector(showConfigWindow), keyEquivalent: "`")
        settings.target = self

        let menu = NSMenu()
        menu.addItem(settings)
        return menu
    }
    
    @objc func showConfigWindow() {
        if let appDelegae = NSApplication.shared.delegate as? AppDelegate, let cfgWindow = appDelegae.cfgWindow {
            if Thread.isMainThread {
                cfgWindow.orderFront(nil)
            } else {
                DispatchQueue.main.async {
                    cfgWindow.orderFront(nil)
                }
            }
        }
    }
    
    
    override func recognizedEvents(_ sender: Any!) -> Int {
        os_log(.debug, log: log, "recognizedEvents")
        return Int(NSEvent.EventTypeMask.Element(arrayLiteral: .keyDown, .flagsChanged).rawValue)
    }
    
    func switchInputMode() {
        self.inputHanlder.isEnMode.toggle()
        if self.inputHanlder.isEnMode {
            self.inputModelabel.stringValue = "英"
        } else {
            self.inputModelabel.stringValue = "中"
        }
        self.inputModePanel.setFrame(findPosition(), display: false)
        if Thread.isMainThread {
            hideCadidatesWindow()
            hideTransPanel()
            inputModePanel.orderFront(nil)
        } else {
            DispatchQueue.main.async {
                self.inputModePanel.orderFront(nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.inputModePanel.orderOut(nil)
        }
    }
}


