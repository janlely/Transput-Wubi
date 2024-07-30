//
//  TransputInputController.swift
//  Transput
//
//  Created by jin junjie on 2024/7/25.
//

import Cocoa
import InputMethodKit
import os.log
let log = OSLog(subsystem: "com.ensan.inputmethod.Transput", category: "inputmethod")
let logLevel: OSLogType = logLevel



@objc(TransputInputController)
class TransputInputController: IMKInputController {
    
    
    private var candidatesWindow: IMKCandidates
    private var composingText: ComposingText = ComposingText(4) //五笔最长是4个编码
    private var candidateArray: [String]! = []
    private var button: NSButton!

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        os_log(logLevel, log: log, "init")
        self.candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel)
        super.init(server: server, delegate: delegate, client: inputClient)
//        panel.contentView?.addSubview(button)
//        let constraints = [
//            button.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor),
//            button.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor),
//            button.topAnchor.constraint(equalTo: panel.contentView!.topAnchor),
//            button.bottomAnchor.constraint(equalTo: panel.contentView!.bottomAnchor)
//        ]
//        NSLayoutConstraint.activate(constraints)
    }

    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        
        os_log(logLevel, log: log, "handle,进行输入处理程序")
        guard let client = sender as? IMKTextInput else {
            return false
        }
        os_log(logLevel, log: log, "handle,开始进行输入处理")
        
        switch event.keyCode {
        case 51: //backspace
            os_log(logLevel, log: log, "handler,处理退格")
            return handlerBackspace()
        case 49: //Space
            os_log(logLevel, log: log, "handler,处理空格")
            return handlerSpace()
        case 36: //Enter
            os_log(logLevel, log: log, "handler,处理回车")
            return handlerEnter()
        default:
            os_log(logLevel, log: log, "handler,处理其他字符")
            guard let text = event.characters,
                  text.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0.isPunctuation || $0.isSymbol) }) else {
                return false
            }
            os_log(logLevel, log: log, "handler,处理字母、数字、标点、符号")
            return handlerInput(text.first!)
        }
    }
    
    
    override func candidates(_ sender: Any!) -> [Any]! {
        os_log(logLevel, log: log, "生成候选词")
        self.candidateArray = makeCandidates(sender)
        return candidateArray
    }

    override func candidateSelected(_ candidateString: NSAttributedString!) {
        os_log(logLevel, log: log, "选择候选词: %s", candidateString.string)
        composingText.select(candidateString.string)
        os_log(logLevel, log: log, "标记用户输入: %s", composingText.joined())
        self.candidatesWindow.hide()
        setMarkedText(composingText.joined())
    }
    
    
    func handlerBackspace() -> Bool {
        if composingText.isEmpty() {
            os_log(logLevel, "输入为空，不处理退格")
            return false
        }
        os_log(logLevel, log: log, "输入不为空，进行退格操作")
        composingText.removeLast()
        self.candidatesWindow.update()
        setMarkedText(composingText.joined())
        return true
    }
    
    func handlerSpace() -> Bool {
        if !candidateArray.isEmpty {
            os_log(logLevel, log: log, "候选词不为空，选择第一个候选词")
            composingText.select(candidateArray[0])
            composingText.newUnit()
            self.candidatesWindow.update()
            self.candidatesWindow.hide()
            setMarkedText(composingText.joined())
            return true
        }
        os_log(logLevel, log: log, "候选词为空，插入一个空格")
        return handlerInput(" ")
    }
    
    func handlerEnter() -> Bool {
        if composingText.isEmpty() {
            return false
        }
        os_log(logLevel, log: log, "输入回车，提交输入到系统")
        self.client().insertText(composingText.joined(), replacementRange: .notFound)
        self.composingText.clear()
        return true
    }
    
    func handlerInput(_ char: Character) -> Bool {
        os_log(logLevel, log: log, "handlerInput, 处理用户输入")
        composingText.input(char, self.candidateArray)
        let joined = composingText.joined()
        os_log(logLevel, log: log, "handlerInput, 设置标记: %{public}s", joined)
        self.candidatesWindow.update()
        if !candidateArray.isEmpty {
            self.candidatesWindow.show()
        }
        setMarkedText(composingText.joined())
        return true
    }
    
    func makeCandidates(_ sender: Any!) -> [String]! {
        let base = composingText.last()
        if base.count <= 0 {
            os_log(logLevel, "makeCandidates,输入为空，返回空的候选词")
            return []
        }
        os_log(logLevel, log: log, "makeCandidates,返回默认候选词")
        return ["一","二","三","四","五"]
    }
    
    func setMarkedText(_ text: String) {
        self.client().setMarkedText(text, selectionRange: .notFound, replacementRange: .notFound)
        if self.candidatesWindow.isVisible() {
            os_log(logLevel, log: log, "候选词窗口可见，不渲染翻译按钮")
            hidePanel()
            return
        }
                    
        //获取标记文本末尾的位置
        let position = findMarkedTextRightBound()
        showPanel(position)
    }
    
    func findMarkedTextRightBound() -> CGPoint {
        // 获取标记文本的范围
        let markedRange = self.client().markedRange()
        // 标记文本的末尾位置
        let position = markedRange.upperBound
        let range = NSRange(location: position, length: 0)
        var actualRange = NSRange()
        let firstRect = self.client().firstRect(forCharacterRange: range, actualRange: &actualRange)
        return CGPoint(x: firstRect.midX, y: firstRect.midY)
    }
    
    @objc func buttonClicked(_ sender: NSButton) {
        // 处理按钮点击事件
        os_log(logLevel, log: log, "点击翻译")
        self.client().insertText(composingText.joined(), replacementRange: .notFound)
        self.composingText.clear()
    }
    
    func getPanel() -> NSPanel? {
        return (NSApplication.shared.delegate as? AppDelegate)?.transPanel
    }
    
    func showPanel(_ position: CGPoint) {
        let transPanel = getPanel()!
        os_log(logLevel, log: log, "翻译按钮显示前, panel可激活属性为: %{public}s, 可见性为: %{public}s",
               transPanel.canBecomeKey ? "YES" : "NO", transPanel.isVisible ? "YES" : "NO")
        os_log(logLevel, log: log, "翻译按钮显示前, panel的isFloatingPanel属性为: %{public}s, isMiniaturized属性为: %{public}s",
               transPanel.isFloatingPanel ? "YES" : "NO", transPanel.isMiniaturized ? "YES" : "NO")
        os_log(logLevel, log: log, "翻译按钮显示前, panel的isKeyWindow属性为: %{public}s, isMainWindow属性为: %{public}s",
               transPanel.isKeyWindow ? "YES" : "NO", transPanel.isMainWindow ? "YES" : "NO")

        transPanel.setFrameOrigin(position)
        getPanel()?.orderFront(nil)
        
        os_log(logLevel, log: log, "翻译按钮显示后, panel可激活属性为: %{public}s, 可见性为: %{public}s",
               transPanel.canBecomeKey ? "YES" : "NO", transPanel.isVisible ? "YES" : "NO")
        os_log(logLevel, log: log, "翻译按钮显示后, panel的isFloatingPanel属性为: %{public}s, isMiniaturized属性为: %{public}s",
               transPanel.isFloatingPanel ? "YES" : "NO", transPanel.isMiniaturized ? "YES" : "NO")
        os_log(logLevel, log: log, "翻译按钮显示后, panel的isKeyWindow属性为: %{public}s, isMainWindow属性为: %{public}s, alphaValue属性为: %{public}.1f",
               transPanel.isKeyWindow ? "YES" : "NO", transPanel.isMainWindow ? "YES" : "NO", transPanel.alphaValue)

    }
    
    func hidePanel() {
        getPanel()?.orderOut(nil)
        
    }
    
    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        os_log(logLevel, log: log, "输入法被激活")
        showPanel(CGPoint(x: 100, y: 100))
    }
    
    override func deactivateServer(_ sender: Any!) {
        os_log(logLevel, log: log, "输入法被停用")
        super.deactivateServer(sender)
        hidePanel()
    }
}

class ComposingText {
    
    private var composingArray: [ComposingUint] = [ComposingUint()]
    private var codeUpperLimit: Int!
    
    init(_ codeUpperLimit: Int!) {
        
        self.codeUpperLimit = codeUpperLimit
    }
    
    func input(_ char: Character, _ candidates: [String]) {
        if char.isLetter && char.isLowercase {
            os_log(logLevel ,"input,输入小字字母")
            return inputLowercaseLetter(char, candidates)
        }
        if char.isNumber {
            os_log(logLevel, log: log, "input,输入数字")
            return inputNumber(char, candidates)
        }
        os_log(logLevel, log: log, "input,输入符号")
        return inputOtherSymble(char, candidates)
    }
    
    func inputLowercaseLetter(_ char: Character, _ candidates: [String]) {
        //如果当前的格子编码数量达到上限，则自动选择第一个候选词
        if composingArray.last!.length() >= codeUpperLimit && !candidates.isEmpty {
            os_log(logLevel, log: log, "inputLowercaseLetter,格子内容达上限: %s", composingArray.last!.getText())
            composingArray.last!.replace(candidates[0])
            composingArray.last!.autoChange()
            //添加一个新格子
            composingArray.append(ComposingUint())
        }
        //更新当前格子内容
        if composingArray.isEmpty {
            os_log(logLevel, log: log, "inputLowercaseLetter,输入数组为空")
            //添加一个新格子
            composingArray.append(ComposingUint())
        }
        os_log(logLevel, log: log, "inputLowercaseLetter,追加一个字符,数组内容为: %s", joined())
        composingArray.last!.append(char)
    }
    
    func inputNumber(_ char: Character, _ candidates: [String]) {
        //如果数字对应的候选词存在，则选择对应的候选词
        let idx = Int(String(char))!
        if candidates.count >= idx {
            os_log(logLevel, log: log, "inputNumber,候选词数量大于对应数字")
            composingArray.last!.replace(candidates[idx - 1])
            composingArray.last!.manualChange()
            //添加一个新格子
            composingArray.append(ComposingUint())
            return
        }
        os_log(logLevel, log: log, "inputNumber,插入数字,数组内容为:%s", joined())
        //更新当前格子内容
        composingArray.last!.append(char)
        //添加一个新格子
        composingArray.append(ComposingUint())
    }
    
    func inputOtherSymble(_ char: Character, _ candidates: [String]) {
        //如果候选词存在，则选择第一个候选词
        if candidates.count > 0  {
            os_log(logLevel, log: log, "inputOtherSymble,候选词列表不为空，选择第一个候选词")
            composingArray.last!.replace(candidates[0])
            composingArray.last!.manualChange()
        }
        os_log(logLevel, log: log, "inputOtherSymble,添加一个空的单元并插入符号")
        composingArray.append(ComposingUint())
        composingArray.last!.append(char)
        //添加一个新格子
        composingArray.append(ComposingUint())
    }
    
    func joined() -> String {
        return composingArray.map { $0.getText() }.joined()
    }
    
    func last() -> String {
        return composingArray.last!.getText()
    }
    
    func select(_ value: String) {
        composingArray.last!.replace(value)
        composingArray.last!.manualChange()
        composingArray.append(ComposingUint())
    }
     
    func isEmpty() -> Bool {
        return composingArray.count == 1 && composingArray[0].getText() == ""
    }
    
    func removeLast() {
        os_log(logLevel, log: log, "removeLast,最后格子的内容为:%s", composingArray.last!.getText())
        composingArray.last!.removeLast()
        if composingArray.last!.getText() == "" {
            if isEmpty() {
                os_log(logLevel, log:log, "removeLast,数组为空")
                return
            }
            os_log(logLevel, log: log, "removeLast,删除空格子")
            composingArray.removeLast()
            composingArray.last!.unselect()
        }
    }
    
    func newUnit() {
        composingArray.append(ComposingUint())
    }
    
    func clear() {
        composingArray.removeAll()
        composingArray.append(ComposingUint())
    }
}

class ComposingUint {
    
    private var text1: String = "" //用来生成预览的
    private var text2: String = "" //保存编码的
    private var state: ComposingUintState = .UNCHANGED
    
    func length() -> Int {
        return text1.count
    }
    
    func replace(_ value: String) {
        os_log(logLevel, log: log, "replace,替换: %s", value)
        text1 = value
    }
    
    func autoChange() {
        state = .AUTO_CHANGED
    }
    func manualChange() {
        state = .MANUALLY_CHANGED
    }
    
    func append(_ char: Character) {
        text1 += String(char)
        text2 += String(char)
    }
    
    func getText() -> String {
        return text1
    }
    
    func removeLast() {
        if text1 == "" {
            os_log(logLevel, log: log, "removeLast,你不应该看到这一行")
        }
        text1.removeLast()
        text2.removeLast()
    }
    
    func unselect() {
        if state == .AUTO_CHANGED {
            text1 = text2
        }
    }
}

enum ComposingUintState {
    case UNCHANGED
    case MANUALLY_CHANGED
    case AUTO_CHANGED
}
