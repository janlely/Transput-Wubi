//
//  Trie.swift
//  Transput
//
//  Created by jin junjie on 2024/7/30.
//

import Foundation
import os.log

class TrieNode: Codable {
    var children: [UInt8: TrieNode] = [:]
    var code: UInt8?
    var words: [String] = []
    func append(_ words: [String]) {
        if self.words.count < 10 {
            self.words += words.filter {word in !self.words.contains(word)}
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case children, code, words
    }
    
    init(_ code: UInt8) {
        self.code = code
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        children = try container.decode([UInt8: TrieNode].self, forKey: .children)
        code = try container.decodeIfPresent(UInt8.self, forKey: .code)
        words = try container.decode([String].self, forKey: .words)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(children, forKey: .children)
        try container.encode(code, forKey: .code)
        try container.encode(words, forKey: .words)
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
            let parts = trimmedLine.split(separator: " ", maxSplits: 1)
            if parts.count == 2 {
                let code = String(parts[0])
                let word = String(parts[1])
                Trie.insert(root: result, code: code, words: [word])
            }
        }
        return result
    }
    
    func saveAsBin(root: TrieNode, url: URL) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            let data = try encoder.encode(root)
            try data.write(to: url)
        } catch {
            os_log(.error, log: log, "存储词库失败")
        }
    }
    
    func loadFromBin(url: URL) -> TrieNode? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            let root = try decoder.decode(TrieNode.self, from: data)
            return root
        } catch {
            os_log(.error, log: log, "读取词库失败")
            return nil
        }
    }
    
    static func insert(root: TrieNode, code: String, words: [String]) {
        guard let head = code.first?.asciiValue else {
            return
        }
        if root.children[head] == nil {
            root.children[head] = TrieNode(head)
        }
        root.children[head]!.append(words)
        insert(root: root.children[head]!, code: String(code.dropFirst()), words: words)
    }
    
    static func search(root: TrieNode, code: String) -> [String] {
        guard let head = code.first?.asciiValue, root.children[head] != nil else {
            return []
        }
        if code.count == 1 {
            return root.children[head]!.words
        }
        return search(root: root.children[head]!, code: String(code.dropFirst()))
    }
}
