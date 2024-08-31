//
//  InputProcesser.swift
//  Transput-Wubi
//
//  Created by jin junjie on 2024/8/30.
//

import Foundation
import os.log

class InputProcesser {
    
    public var composingString: String = ""
    var cursorPos: Int = 0
    var codeCount: Int = 0
    private let codeLimit: Int = 4
    var cadidatesArray: [String] = [] //当前候选词列表
    var isEnMode: Bool = false
    private var wubiDict: TrieNode! //五笔词库


    func processInput(_ charType: CharType) -> ResultState {
        switch charType {
        case .backspace:
            if composingString.isEmpty {
                return .ignore
            }
            let range = Range(NSMakeRange(cursorPos - 1, 1), in: composingString)
            composingString = composingString.replacingCharacters(in: range!, with: "")
            cursorPos -= 1
            return .typing
        case .enter:
            if composingString.isEmpty {
                return .ignore
            }
            return .commit
        case .lower(let char):
            if codeCount == codeLimit {
                if let cadidate = cadidatesArray.first {
                    let range = Range(NSMakeRange(cursorPos - codeLimit, 4), in: composingString)
                    composingString = composingString.replacingCharacters(in: range!, with: cadidate)
                    cursorPos = cursorPos - codeLimit + cadidate.count
                }
                codeCount = 0
            }
            composingString.insert(char: char, at: cursorPos)
            cursorPos += 1
            codeCount = isEnMode ? 0 : codeCount + 1
            return .typing
        case .number(let char):
            if let cadidate = cadidatesArray[safe: Int(String(char))!] {
                let range = Range(NSMakeRange(cursorPos - codeCount, codeCount), in: composingString)
                composingString = composingString.replacingCharacters(in: range!, with: cadidate)
                cursorPos = cursorPos - codeCount + cadidate.count
            } else {
                composingString.insert(char: char, at: cursorPos)
                cursorPos += 1
                codeCount = 0
            }
            return .conditionalCommit
        case .other(let char):
            if codeCount == codeLimit {
                if let cadidate = cadidatesArray.first {
                    let range = Range(NSMakeRange(cursorPos - codeLimit, 4), in: composingString)
                    composingString = composingString.replacingCharacters(in: range!, with: cadidate)
                    cursorPos = cursorPos - codeLimit + cadidate.count
                }
            }
            composingString.insert(char: char, at: cursorPos)
            cursorPos += 1
            codeCount = 0
            return .conditionalCommit
        case .space:
            if let cadidate = cadidatesArray.first {
                let range = Range(NSMakeRange(cursorPos - codeCount, codeCount), in: composingString)
                composingString = composingString.replacingCharacters(in: range!, with: cadidate)
                cursorPos = cursorPos - codeCount + cadidate.count
            } else {
                composingString.insert(char: " ", at: cursorPos)
                cursorPos += 1
            }
            codeCount = 0
            return .conditionalCommit
        case .left:
            codeCount = 0
            cursorPos = cursorPos > 0 ? cursorPos - 1 : 0
            return .typing
        case .right:
            codeCount = 0
            cursorPos = cursorPos < composingString.count ? cursorPos + 1 : cursorPos
            return .typing
        }
    }
    
    func makeCadidates() -> [String] {
        if isEnMode {
            os_log(.info, log: log, "isEnMode,返回空的候选词")
            self.cadidatesArray = []
            return []
        }
        if codeCount == 0 {
            os_log(.info, log: log, "isLocked,返回空的候选词")
            self.cadidatesArray = []
            return []
        }
        guard let range = Range(NSMakeRange(cursorPos - codeCount, codeCount), in: composingString),
              let base = self.composingString[safe: range] else {
            os_log(.info, log: log, "makeCandidates,输入为空，返回空的候选词")
            self.cadidatesArray = []
            return []
        }
        if base.count <= 0 {
            os_log(.info, log: log, "makeCandidates,输入为空，返回空的候选词")
            self.cadidatesArray = []
            return []
        }
        os_log(.info, log: log, "makeCandidates,从Trie中搜索候选词, base: %{public}s", String(base))
        self.cadidatesArray = Trie.search(root: self.wubiDict, code: String(base))
        return self.cadidatesArray
    }

    func clear() {
        composingString = ""
        cursorPos = 0
        codeCount = 0
        cadidatesArray  = []
        isEnMode = false
    }
    
    func dictLoaded() -> Bool {
        return self.wubiDict != nil
    }
    
    func loadDict() {
        self.wubiDict = Trie.loadFromText("wubi86_jidian.dict")
    }
    
    func select(_ value: String) -> String {
        let range = Range(NSMakeRange(cursorPos - codeCount, codeCount), in: composingString)
        composingString = composingString.replacingCharacters(in: range!, with: value)
        cursorPos = cursorPos - codeCount + value.count
        return composingString
    }
}

enum ResultState {
    case ignore
    case commit
    case conditionalCommit
    case typing
}


extension String {
    mutating func insert(char: Character, at index: Int) {
        let newIndex = self.index(self.startIndex, offsetBy: index)
        self.insert(char, at: newIndex)
    }
    
    subscript(safe range: Range<String.Index>) -> Substring? {
        guard !range.isEmpty,
              range.lowerBound >= startIndex,
              range.upperBound <= endIndex,
              indices.contains(range.lowerBound)
        else { return nil }
        
        return self[range]
    }
}

extension Collection {

    /// Returns the element at the specified index if it exists, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
