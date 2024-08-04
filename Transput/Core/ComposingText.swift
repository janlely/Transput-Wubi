//
//  ComposingText.swift
//  Transput
//
//  Created by jin junjie on 2024/7/31.
//

import Foundation
import os.log

class ComposingText {
    
    private var composingArray: [ComposingUint] = []
    private var codeUpperLimit: Int!
    
    init(_ codeUpperLimit: Int!) {
        
        self.codeUpperLimit = codeUpperLimit
    }
    
    func appendUnit(_ char: Character) {
        composingArray.append(ComposingUint(String(char)))
    }
    
    func input(_ char: Character, _ candidates: [String]) -> Bool {
        if composingArray.isEmpty {
            composingArray.append(ComposingUint(String(char)))
            return false
        }
        if char.isLetter && char.isLowercase {
            os_log(.info ,"input,输入小字字母")
            return inputLowercaseLetter(char, candidates)
        }
        if char.isNumber {
            os_log(.info, log: log, "input,输入数字")
            return inputNumber(char, candidates)
        }
        os_log(.info, log: log, "input,输入符号")
        return inputOtherSymble(char, candidates)
    }
    
    func inputLowercaseLetter(_ char: Character, _ candidates: [String]) -> Bool {
        //如果当前的格子编码数量达到上限，则自动选择第一个候选词
        if composingArray.last!.length() >= codeUpperLimit && !candidates.isEmpty {
            os_log(.info, log: log, "inputLowercaseLetter,格子内容达上限: %{public}s", self.composingArray.last!.getText())
            composingArray.last!.replace(candidates[0])
            composingArray.last!.autoChange()
            //添加一个新格子
            appendUnit(char)
            return false
        }
        //更新当前格子内容
        os_log(.info, log: log, "inputLowercaseLetter,追加一个字符,数组内容为: %{public}s", self.joined())
        composingArray.last!.append(char)
        return false
    }
    
    func inputNumber(_ char: Character, _ candidates: [String]) -> Bool {
        //如果数字对应的候选词存在，则选择对应的候选词
        let idx = Int(String(char))!
        if candidates.count >= idx {
            os_log(.info, log: log, "inputNumber,候选词数量大于对应数字")
            composingArray.last!.replace(candidates[idx - 1])
            composingArray.last!.manualChange()
            //添加一个新格子，用于后续的输入
            composingArray.append(ComposingUint(""))
            return !ConfigModel.shared.useAITrans
        }
        os_log(.info, log: log, "inputNumber,插入数字,数组内容为:%{public}s", joined())
        //更新当前格子内容
        composingArray.last!.append(char)
        //添加一个新格子
        composingArray.append(ComposingUint(""))
        return false
    }
    
    func inputOtherSymble(_ char: Character, _ candidates: [String]) -> Bool {
        //如果候选词存在，则选择第一个候选词
        if candidates.count > 0  {
            os_log(.info, log: log, "inputOtherSymble,候选词列表不为空，选择第一个候选词")
            composingArray.last!.replace(candidates[0])
            composingArray.last!.manualChange()
        }
        os_log(.info, log: log, "inputOtherSymble,添加一个空的单元并插入符号")
        appendUnit(convertPunctuation(char))
        //添加一个新格子
        composingArray.append(ComposingUint(""))
        return false
    }
    
    func joined() -> String {
        return composingArray.map { $0.getText() }.joined()
    }
    
    func last() -> String? {
        if composingArray.isEmpty {
            return nil
        }
        guard let last = composingArray.last else {
            os_log(.info, log: log, "composingArray.last不存在")
            return nil
        }
        return last.getText()
    }
    
    func select(_ value: String) {
        composingArray.last!.replace(value)
        composingArray.last!.manualChange()
        composingArray.append(ComposingUint(""))
    }
    
    func isEmpty() -> Bool {
        return composingArray.isEmpty
    }
    
    func handlerBackspace() -> Bool {
        if composingArray.isEmpty {
            os_log(.info, log: log, "输入内容为空，不处理退格")
            return false
        }
        os_log(.info, log: log, "removeLast,最后格子的内容为: %{public}s", self.composingArray.last!.getText())
        //删除空的格子
        if composingArray.last!.isEmpty() {
            composingArray.removeLast()
        }
        //没有格子了，返回false
        if composingArray.isEmpty {
            return false
        }
        //对格子进行unselect操作
        composingArray.last!.unselect()
        //如果格子不是空的，则执行删除操作
        if !composingArray.last!.isEmpty() {
            composingArray.last!.removeLast()
            return true
        }
        //格子还是空的，删除空格子
        composingArray.removeLast()
        return handlerBackspace()
    }
    
    func newUnit() {
        composingArray.append(ComposingUint(""))
    }
    
    func clear() {
        composingArray.removeAll()
    }
}

class ComposingUint {
    
    private var text1: String = "" //用来生成预览的
    private var text2: String = "" //保存编码的
    private var state: ComposingUintState = .UNCHANGED
    
    init(_ char: String) {
        text1 = char
        text2 = char
    }
    
    func isEmpty() -> Bool {
        return text1.isEmpty
    }
    
    func length() -> Int {
        return text1.count
    }
    
    func replace(_ value: String) {
        os_log(.info, log: log, "replace,替换: %{publc}s", value)
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
            os_log(.info, log: log, "removeLast,当前格子内容为空")
            return
        }
        text1.removeLast()
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

