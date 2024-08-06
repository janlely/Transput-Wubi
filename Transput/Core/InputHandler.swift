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
    private var isSelectedArray: [Bool] = [] //每个格子表示一次输入, 是否有选择候选词
    private var cadidatesArray: [String] = [] //当前候选词列表
    private var state: InputState = .start //当前的状态
    private var wubiDict: TrieNode! //五笔词库
    
    func handlerInput(_ charType: CharType) -> InputResult {
        switch doHandlerInput(charType) {
        case .ignore:
            return .ignore
        case .conditionalCommit:
            return .conditionalCommit(content: self.composingArray.joined())
        case .commit:
            return .commit(content: self.composingArray.joined())
        case .done:
            return .continute(content: self.composingArray.joined())
        }
    }
    
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
    
    private func doHandlerInput(_ charType: CharType) -> InnerResult {
        switch state {
        case .start:
            switch charType {
            case .lower(let char): //小写字母 -> 添加一个空格 -> 输入字符 -> .inputing
                addUnit()
                doInput(char)
                self.state = .inputing
                return .done
            case .other(let char):
                addUnit()
                doInput(char)
                self.state = .inputing
                return .commit
            default:
                return .ignore
            }
        case .inputing:
            switch charType {
            case .lower(let char), .other(let char):
                if hitLimit() {
                    self.state = .autoSelecting
                    return doHandlerInput(charType)
                }
                doInput(char)
                return .done
            case .space, .number:
                self.state = .manuallySeleting
                return doHandlerInput(charType)
            case .backspace:
                let back = back()
                if !back {
                    return .done
                }
                if self.composingArray.isEmpty {
                    self.state = .start
                } else {
                    let count = self.composingArray.count
                    if self.isSelectedArray[count - 1] {
                        self.state = .start2
                    } else {
                        self.unSelect()
                        self.state = .inputing
                    }
                }
                return .done
            case .enter:
                self.state = .start
                return .commit
            }
        case .autoSelecting:
            switch charType {
            case .lower(let char), .other(let char):
                if !self.cadidatesArray.isEmpty {
                    doSelect(0, true)
                }
                addUnit()
                doInput(char)
                self.state = .inputing
                return .done
            default:
                os_log(.error, log: log, "autoSelecting状态下charType不为lower或者other")
                return .commit
            }
        case .manuallySeleting:
            switch charType {
            case .space:
                if !self.cadidatesArray.isEmpty {
                    doSelect(0, false)
                }
                self.state = .start2
                return .conditionalCommit
            case .number(let char):
                if let idx = Int(String(char)), !self.cadidatesArray.isEmpty && self.cadidatesArray.count >= idx {
                    doSelect(idx - 1, false)
                    self.state = .start2
                } else {
                    addUnit()
                    doInput(char)
                    self.state = .inputing
                }
                return .conditionalCommit
            default:
                os_log(.error, log: log, "manuallySelecting状态下charType不为space或者number")
                return .commit
            }
        case .start2:
            switch charType {
            case .lower(let char), .number(let char), .other(let char): //小写字母 -> 添加一个空格 -> 输入字符 -> .inputing
                addUnit()
                doInput(char)
                self.state = .inputing
                return .done
            case .space:
                addUnit()
                doInput(" ")
                self.state = .inputing
                return .done
            case .backspace:
                let back = back()
                if !back {
                    return .done
                }
                if self.composingArray.isEmpty {
                    self.state = .start
                } else {
                    self.unSelect()
                    self.state = .inputing
                }
                return .done
            case .enter:
                return .commit
            }
        }
    }
    
    private func addUnit() {
        self.composingArray.append("")
        self.rawCodeArray.append("")
        self.isSelectedArray.append(false)
    }
    
    private func doInput(_ char: Character) {
        let count = self.composingArray.count
        self.composingArray[count - 1].append(char)
        self.rawCodeArray[count - 1].append(char)
    }
    
    private func unSelect() {
        let count = self.composingArray.count
        self.composingArray[count - 1] = self.rawCodeArray[count - 1]
    }
    
    private func back() -> Bool {
        let count = self.composingArray.count
        self.composingArray[count - 1] = String(self.composingArray[count - 1].dropLast())
        self.rawCodeArray[count - 1] = self.composingArray[count - 1]
        if self.composingArray.last!.count == 0 {
            self.composingArray.removeLast()
            self.rawCodeArray.removeLast()
            self.isSelectedArray.removeLast()
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
            self.isSelectedArray[count - 1] = true
        }
    }
    
    private enum InnerResult {
        case ignore
        case commit
        case conditionalCommit
        case done
    }
}

enum InputResult {
    case ignore
    case commit(content: String)
    case conditionalCommit(content: String)
    case continute(content: String)
}
