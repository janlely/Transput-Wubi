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
    private var button: NSButton!
    private var transPanel: NSPanel!
    private var wubiDict: TrieNode!

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        os_log(.info, log: log, "init")
        self.candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel)
        super.init(server: server, delegate: delegate, client: inputClient)
        initTransPanel()
    }
    
    func initTransPanel() {
        os_log(.info, log: log, "初始化翻译面板")
        transPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 20, height: 20),
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
        
        
        let iconButton = NSButton(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
        iconButton.imageScaling = .scaleProportionallyDown
        iconButton.image = NSImage(named: "icons8-t-26")
        iconButton.isBordered = false
        iconButton.target = self
        iconButton.layer?.backgroundColor = NSColor.white.cgColor
        iconButton.action = #selector(buttonClicked)
        transPanel.contentView?.addSubview(iconButton)
        
    }

    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        
        os_log(.info, log: log, "handle,进行输入处理程序")
        if !(sender is IMKTextInput) {
            os_log(.error, log: log, "sender不是IMKTextInput")
            return false
        }
        os_log(.info, log: log, "handle,开始进行输入处理")
        
        switch event.keyCode {
        case 51: //backspace
            os_log(.info, log: log, "handler,处理退格")
            return handlerBackspace()
        case 49: //Space
            os_log(.info, log: log, "handler,处理空格")
            return handlerSpace()
        case 36: //Enter
            os_log(.info, log: log, "handler,处理回车")
            return handlerEnter()
        default:
            os_log(.info, log: log, "handler,处理其他字符")
            guard let text = event.characters,
                  text.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0.isPunctuation || $0.isSymbol) }) else {
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
        os_log(.info, log: log, "makeCandidates,从Trie中搜索候选词")
        return Trie.search(root: wubiDict, code: base)
    }
    
    func setMarkedText(_ text: String) {
        os_log(.info, log: log, "marked text: #%{public}s#", text)
        self.client().setMarkedText(text, selectionRange: .notFound, replacementRange: .notFound)
        self.candidatesWindow.update()
        if self.candidateArray.isEmpty {
            self.candidatesWindow.hide()
            if !text.isEmpty {
                //获取标记文本末尾的位置
                let position = findMarkedTextRightBound()
                showPanel(position)
            } else {
                hidePanel()
            }
            return
        }
        hidePanel()
        self.candidatesWindow.show()
    }
    
    func findMarkedTextRightBound() -> CGPoint {
        // 获取标记文本的范围
        let markedRange = self.client().markedRange()
        // 标记文本的末尾位置
        let position = markedRange.upperBound
        let range = NSRange(location: position, length: 0)
        var actualRange = NSRange()
        let firstRect = self.client().firstRect(forCharacterRange: range, actualRange: &actualRange)
        return CGPoint(x: firstRect.midX, y: firstRect.midY - 10)
    }
    
    @objc func buttonClicked(_ sender: NSButton) {
        // 处理按钮点击事件
        os_log(.info, log: log, "点击翻译")
        sender.image = NSImage(named: "icons8-loading-24")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 这里的代码会在 2 秒后执行
            self.client().insertText("one", replacementRange: .notFound)
            self.composingText.clear()
            sender.image = NSImage(named: "icons8-t-26")
            self.hidePanel()
        }
    }
    
    
    func showPanel(_ position: CGPoint) {
        os_log(.info, log: log, "显示翻译按钮")
        transPanel.setFrameOrigin(position)
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
        if wubiDict != nil {
            os_log(.info, log: log, "字典已加载，无需重复加载")
            return
        }
        os_log(.info, log: log, "loading wubi: \(Date().timeIntervalSince1970)")
        wubiDict = Trie.loadFromText("better-wubi.dict")
        os_log(.info, log: log, "wubi loaded: \(Date().timeIntervalSince1970)")
    }
    
    override func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        os_log(.info, log: log, "停用输入法")
        self.candidatesWindow.hide()
        hidePanel()
    }
}


