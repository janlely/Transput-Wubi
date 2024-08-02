//
//  Trie.swift
//  Transput
//
//  Created by jin junjie on 2024/7/30.
//

import Foundation
import os.log

class TrieNode {
    var children: [UInt8: TrieNode] = [:]
    var code: UInt8?
    var words: [Word] = []
    func append(_ word: Word) {
        if self.words.contains(where: { $0.value == word.value }) {
            return
        }
        self.words.insertSorted(word)
        if self.words.count > 10 {
            self.words.removeLast()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case children, code, words
    }
    
    init(_ code: UInt8) {
        self.code = code
    }
    
}

struct Word: Comparable {
    let value: String
    let weight: Int
    
    static func < (lhs: Word, rhs: Word) -> Bool {
        return lhs.weight > rhs.weight
    }
    
    static func == (lhs: Word, rhs: Word) -> Bool {
        return lhs.value == rhs.value
    }
    
    func multiplyBy(_ coefficient: Int) -> Word {
        return Word(value: value, weight: self.weight * coefficient)
    }
}


class Trie {
    
//    private var root: TrieNode = TrieNode(0)
    
    static func loadFromText(_ filename: String) -> TrieNode? {
        
        guard let path = Bundle.main.path(forResource: filename, ofType: nil) else {
            os_log(.error, log: log, "Cannot find file: \(filename)")
            return nil
        }
        
        guard let filePointer = fopen(path, "r") else {
            os_log(.error, log: log, "Error opening file")
            return nil
        }
        defer {
            fclose(filePointer)
        }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        
        let result = TrieNode(0)
        while fgets(buffer, Int32(bufferSize), filePointer) != nil {
            let line = String(cString: buffer)
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmedLine.split(separator: " ", maxSplits: 2)
            if parts.count == 3 {
                let word = String(parts[0])
                let code = String(parts[1])
                guard let weight = Int(parts[2]) else {
                    continue
                }
                Trie.insert(root: result, code: code, word: Word(value: word, weight: weight))
            }
        }
        return result
    }
    
    
    static func insert(root: TrieNode, code: String, word: Word) {
        guard let head = code.first?.asciiValue else {
            return
        }
        if root.children[head] == nil {
            root.children[head] = TrieNode(head)
        }
        let tail = String(code.dropFirst())
        root.children[head]!.append(word.multiplyBy(weigthCoef(tail.count)))
        insert(root: root.children[head]!, code: tail, word: word)
    }
    
    static func search(root: TrieNode, code: String) -> [String] {
        guard let head = code.first?.asciiValue, root.children[head] != nil else {
            return []
        }
        if code.count == 1 {
            return root.children[head]!.words.map {$0.value}
        }
        return search(root: root.children[head]!, code: String(code.dropFirst()))
    }
}
