//
//  InputHandler.swift
//  Transput
//
//  Created by jin junjie on 2024/8/5.
//

import Foundation
import os.log

class InputHandler {
    
    private var composingArray: [String] = [] //每个格子表示一次输入, 编码后
    private var rawCodeArray: [String] = [] //每个格子表示一次输入, 原始编码
    private var isLockedArray: [Bool] = [] //每个格子表示一次输入, 是否有选择候选词
    private var cadidatesArray: [String] = [] //当前候选词列表
    private var state: InputState = .start //当前的状态
    private var wubiDict: TrieNode! //五笔词库
    public var isEnMode: Bool = false
    
    func dictLoaded() -> Bool {
        return self.wubiDict != nil
    }
    
    func loadDict() {
        self.wubiDict = Trie.loadFromText("wubi86_jidian.dict")
    }
    
    func getCompsingText() -> String {
        return self.composingArray.joined()
    }
    
    func hasCadidates() -> Bool {
        os_log(.info, log: log, "候选词: %{public}s", self.cadidatesArray.joined(separator: ","))
        return !self.cadidatesArray.isEmpty
    }
    
    func select(_ value: String) -> String {
        let count = self.composingArray.count
        self.composingArray[count - 1] = value
        return self.composingArray.joined()
    }
    
    func makeCadidates() -> [String] {
        if isEnMode {
            os_log(.info, log: log, "isEnMode,返回空的候选词")
            self.cadidatesArray = []
            return []
        }
        if let isLocked = self.isLockedArray.last, isLocked {
            os_log(.info, log: log, "isLocked,返回空的候选词")
            self.cadidatesArray = []
            return []
        }
        guard let base = self.composingArray.last else {
            os_log(.info, log: log, "makeCandidates,输入为空，返回空的候选词")
            self.cadidatesArray = []
            return []
        }
        if base.count <= 0 {
            os_log(.info, log: log, "makeCandidates,输入为空，返回空的候选词")
            self.cadidatesArray = []
            return []
        }
        os_log(.info, log: log, "makeCandidates,从Trie中搜索候选词, base: %{public}s", base)
        self.cadidatesArray = Trie.search(root: self.wubiDict, code: base)
        return self.cadidatesArray
    }
    
    func clear() {
        self.composingArray.removeAll()
        self.rawCodeArray.removeAll()
        self.cadidatesArray.removeAll()
        self.state = .start
    }
    
    public func handlerInput(_ charType: CharType) -> InputResult {
        switch state {
        case .start:
            switch charType {
            case .lower(let char): //小写字母 -> 添加一个空格 -> 输入字符 -> .inputing
                addUnit()
                doInput(char)
                self.state = .inputing
                return .continute
            case .other(let char):
                addUnit(true)
                doInput(convertPunctuation(char))
                self.state = .start2
                return .commit
            case .space:
                addUnit(true)
                doInput(" ")
                self.state = .start
                return .commit
            default:
                return .ignore
            }
        case .inputing:
            switch charType {
            case .lower(let char):
                if isEnMode {
                    addUnit(true)
                    doInput(char)
                    self.state = .start2
                    return .continute
                }
                if hitLimit() {
                    self.state = .autoSelecting
                    return handlerInput(charType)
                }
                doInput(char)
                return .continute
            case .other(let char):
                if isEnMode {
                    doInput(char)
                    return .continute
                }
                self.state = .autoSelecting
                return handlerInput(charType)
            case .space:
                if isEnMode {
                    doInput(" ")
                    return .continute
                }
                self.state = .manuallySeleting
                return handlerInput(charType)
            case .number(let char):
                if isEnMode {
                    doInput(char)
                    return .continute
                }
                self.state = .manuallySeleting
                return handlerInput(charType)
            case .backspace:
                let droped = backAndDrop()
                if !droped {
                    return .continute
                }
                if self.composingArray.isEmpty {
                    self.state = .start
                } else {
                    let count = self.composingArray.count
                    if self.isLockedArray[count - 1] {
                        self.state = .start2
                    } else {
                        self.unSelect()
                        self.state = .inputing
                    }
                }
                return .continute
            case .enter:
                self.state = .start
                return .commit
            }
        case .autoSelecting:
            switch charType {
            case .lower(let char):
                if !self.cadidatesArray.isEmpty {
                    doSelect(0, true)
                }
                addUnit()
                doInput(char)
                self.state = .inputing
                return .continute
            case .other(let char):
                if !self.cadidatesArray.isEmpty {
                    doSelect(0, true)
                }
                addUnit(true)
                doInput(isEnMode ? char : convertPunctuation(char))
                self.state = .start2
                return .conditionalCommit
            default:
                os_log(.error, log: log, "autoSelecting状态下charType不为lower或者other")
                return .commit
            }
        case .manuallySeleting:
            switch charType {
            case .space:
                if !self.cadidatesArray.isEmpty {
                    doSelect(0, false)
                } else {
                    addUnit(true)
                    doInput(" ")
                }
                self.state = .start2
                return .conditionalCommit
            case .number(let char):
                if let idx = Int(String(char)), !self.cadidatesArray.isEmpty && self.cadidatesArray.count >= idx {
                    doSelect(idx - 1, false)
                    self.state = .start2
                    return .conditionalCommit
                }
                addUnit(true)
                doInput(char)
                self.state = .start2
                return .continute
            default:
                os_log(.error, log: log, "manuallySelecting状态下charType不为space或者number")
                return .commit
            }
        case .start2:
            switch charType {
            case .lower(let char): //小写字母 -> 添加一个空格 -> 输入字符 -> .inputing
                if isEnMode {
                    addUnit(true)
                    doInput(char)
                    self.state = .start2
                    return .continute
                }
                addUnit()
                doInput(char)
                self.state = .inputing
                return .continute
            case .number(let char), .other(let char):
                addUnit(true)
                doInput(isEnMode ? char : convertPunctuation(char))
                self.state = .start2
                return .continute
            case .space:
                addUnit(true)
                doInput(" ")
                self.state = .start2
                return .continute
            case .backspace:
                let droped = backAndDrop()
                if !droped {
                    return .continute
                }
                if self.composingArray.isEmpty {
                    self.state = .start
                    return .continute
                }
                let count = self.composingArray.count
                if self.isLockedArray[count - 1] {
                    self.state = .start2
                    return .continute
                }
                self.unSelect()
                self.state = .inputing
                return .continute
            case .enter:
                return .commit
            }
        }
    }
    
    private func addUnit(_ lock: Bool = false) {
        self.composingArray.append("")
        self.rawCodeArray.append("")
        self.isLockedArray.append(lock)
    }
    
    private func doInput(_ char: Character) {
        let count = self.composingArray.count
        self.composingArray[count - 1].append(char)
        self.rawCodeArray[count - 1].append(char)
//        self.isLockedArray[count - 1] = lock
    }

    private func unSelect() {
        let count = self.composingArray.count
        self.composingArray[count - 1] = self.rawCodeArray[count - 1]
    }
    
    private func backAndDrop() -> Bool {
        let count = self.composingArray.count
        self.composingArray[count - 1] = String(self.composingArray[count - 1].dropLast())
        self.rawCodeArray[count - 1] = self.composingArray[count - 1]
        if self.composingArray.last!.count == 0 {
            self.composingArray.removeLast()
            self.rawCodeArray.removeLast()
            self.isLockedArray.removeLast()
            return true
        }
        return false
    }
    
    private func hitLimit() -> Bool {
        return self.composingArray.last!.count >= 4
    }
    
    private func doSelect(_ idx: Int, _ isAuto: Bool) {
        let count = self.composingArray.count
        self.composingArray[count - 1] = self.cadidatesArray[idx]
        if !isAuto {
            self.isLockedArray[count - 1] = true
        }
    }
    
    
    func toggleMode() {
        isEnMode.toggle()
        if !isEnMode {
            self.state = .start2
        }
    }

}

enum InputResult {
    case ignore //忽略当前输入
    case commit //可以提交了
    case conditionalCommit //有条件的提交(未开启AI翻译则为提交)
    case continute //当前输入处理完毕，等待处理后续输入
}
