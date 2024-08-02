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
    private var composingText: ComposingText = ComposingText(4) //五笔最长是4个编码
    private var candidateArray: [String]! = []
    private var transPanel: NSPanel!
    private var transBtn: NSButton!
    private var wubiDict: TrieNode!
    private var transRect: (x: CGFloat, y: CGFloat, height: CGFloat) = (0, 0, 0)
    private var observation: NSKeyValueObservation?
    private var isChecking: Bool = false

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        os_log(.info, log: log, "init")
        self.candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel)
        super.init(server: server, delegate: delegate, client: inputClient)
        initTransPanel()
    }
    
    func initTransPanel() {
        os_log(.info, log: log, "初始化翻译面板")
        transPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
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
        
        
        transBtn = NSButton(title: "翻译成英语", target: nil, action: #selector(buttonClicked))
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

    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        
        os_log(.info, log: log, "handle,进行输入处理程序")
        if !(sender is IMKTextInput) {
            os_log(.error, log: log, "sender不是IMKTextInput")
            return false
        }
        
        switch event.type {
        case .flagsChanged:
            //TODO: 处理特殊按键事件
            os_log(.info, log: log, "特殊按键被按下")
            return true
        case .keyDown:
            return handlerKeyDown(event)
        default:
            return false
        }
        
    }
    
    func handlerKeyDown(_ event: NSEvent!) -> Bool {
        
        os_log(.info, log: log, "handle,开始进行输入处理")
        
        //忽略所有的组合键
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // 如果有任何修饰键被按下，就忽略这个事件
        if modifierFlags.contains(.command) ||
           modifierFlags.contains(.option) ||
            modifierFlags.contains(.control) {
            os_log(.info, log: log, "忽略组合键")
            return false
        }

        switch event.keyCode {
        case 51: //backspace
            os_log(.info, log: log, "handler,处理退格")
            return handlerBackspace()
        case 49: //Space
            os_log(.info, log: log, "handler,处理空格")
            return composingText.isEmpty() ? false : handlerSpace()
        case 36: //Enter
            os_log(.info, log: log, "handler,处理回车")
            return handlerEnter()
        default:
            os_log(.info, log: log, "handler,处理其他字符")
            guard let text = event.characters,
                  text.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0.isPunctuation || $0.isSymbol) }) else {
                os_log(.info, log: log, "不支持的按键: %{public}d", event.keyCode)
                return false
            }
            os_log(.info, log: log, "handler,处理字母、数字、标点、符号")
            return handlerInput(text.first!)
        }
    }
    
    
    override func candidates(_ sender: Any!) -> [Any]! {
        os_log(.info, log: log, "生成候选词")
        self.candidateArray = makeCandidates(sender)
        return candidateArray
    }

    override func candidateSelected(_ candidateString: NSAttributedString!) {
        os_log(.info, log: log, "选择候选词: %s", candidateString.string)
        composingText.select(candidateString.string)
        os_log(.info, log: log, "标记用户输入: %s", composingText.joined())
        self.candidatesWindow.hide()
        setMarkedText(composingText.joined())
    }
    
    
    func handlerBackspace() -> Bool {
        let result = composingText.handlerBackspace()
        setMarkedText(composingText.joined())
        return result
    }
    
    func handlerSpace() -> Bool {
        if !candidateArray.isEmpty {
            os_log(.info, log: log, "候选词不为空，选择第一个候选词")
            return handlerInput("1")
        }
        os_log(.info, log: log, "候选词为空，插入一个空格")
        return handlerInput(" ")
    }
    
    func handlerEnter() -> Bool {
        os_log(.info, log: log, "client.lenght: %{public}d", self.client().length())
        let text = composingText.joined()
        if composingText.isEmpty() || text.isEmpty {
            return false
        }
        os_log(.info, log: log, "输入回车，提交输入到系统")
        self.client().insertText(text, replacementRange: .notFound)
        self.composingText.clear()
        hidePanel()
        self.candidatesWindow.hide()
        return true
    }
    
    func handlerInput(_ char: Character) -> Bool {
        os_log(.info, log: log, "handlerInput, 处理用户输入")
        composingText.input(char, self.candidateArray)
        let joined = composingText.joined()
        os_log(.info, log: log, "handlerInput, 设置标记: %{public}s", joined)
        setMarkedText(joined)
        return true
    }
    
    func makeCandidates(_ sender: Any!) -> [String]! {
        guard let base = composingText.last() else {
            return []
        }
        if base.count <= 0 {
            os_log(.info, "makeCandidates,输入为空，返回空的候选词")
            return []
        }
        os_log(.info, log: log, "makeCandidates,从Trie中搜索候选词, base: %{public}s", base)
        return Trie.search(root: wubiDict, code: base)
    }
    
    func setMarkedText(_ text: String) {
        os_log(.info, log: log, "marked text: #%{public}s#", text)
        self.client().setMarkedText(text, selectionRange: .notFound, replacementRange: .notFound)
        self.candidatesWindow.update()
        if self.candidateArray.isEmpty {
            self.candidatesWindow.hide()
            if text.containsChineseCharacters {
                //获取标记文本末尾的位置
                showPanel()
            } else {
                hidePanel()
            }
            return
        }
        hidePanel()
        self.candidatesWindow.show()
    }
    
    @objc func buttonClicked(_ sender: NSButton) {
        // 处理按钮点击事件
        os_log(.info, log: log, "点击翻译")
    }
    
    
    func showPanel() {
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
        transPanel.setFrame(inputPos, display: false)
        transPanel.orderFront(nil)
    }
    
    func hidePanel() {
        os_log(.info, log: log, "隐藏翻译按钮")
        transPanel.orderOut(nil)
    }
    
    
    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        os_log(.info, log: log, "启用输入法")
        self.candidatesWindow.hide()
        hidePanel()
        composingText.clear()
        candidateArray.removeAll()
        //如果有已经marked的内容，把它提交掉
        if let str = getMarkedText() {
            self.client().insertText(str, replacementRange: .notFound)
        }
        if wubiDict != nil {
            os_log(.info, log: log, "字典已加载，无需重复加载")
            return
        }
        os_log(.info, log: log, "loading wubi: \(Date().timeIntervalSince1970)")
        wubiDict = Trie.loadFromText("wubi86_jidian.dict")
        os_log(.info, log: log, "wubi loaded: \(Date().timeIntervalSince1970)")
    }
    
    override func deactivateServer(_ sender: Any!) {
        os_log(.info, log: log, "停用输入法")
        
        hidePanel()
        super.deactivateServer(sender)
    }
    
    func switchInputMethod() {
        os_log(.info, log: log, "切换到英文输入法")
        // 实现切换到上一个输入法的逻辑
        let inputSource = TISCopyInputSourceForLanguage("en" as CFString).takeRetainedValue()
        TISSelectInputSource(inputSource)
    }
    
    func getMarkedText() -> String? {
        let length = self.client().length()
        guard length > 0 else { return nil}
        
        let range = NSRange(location: 0, length: length)
        let attrString = self.client().attributedSubstring(from: range)
        
        return attrString?.string
    }
    
}


