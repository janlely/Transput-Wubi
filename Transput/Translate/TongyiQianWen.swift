//
//  TongyiQianWen.swift
//  Transput
//
//  Created by jin junjie on 2024/8/2.
//

import Foundation
import os.log

class TongyiQianWen: Translater {
    
    var apiKey: String = "sk-1d2b610c1ffe4c79b1da58c5f5530a11"
    var url: String = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    
    func translate(_ content: String, completion: @escaping (String) -> Void) {
        let request = ChatRequest(model: "qwen-turbo", messages: [
            ChatRequest.Message(role: "system", content: "你是一个中文到英文的翻译，你把我的所有问题中的内容都直接翻译成英文就可以"),
            ChatRequest.Message(role: "user", content: content),
        ])
        
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            HttpClient.post(url: url, parameters:jsonData,
                            headers: [
                                "Content-Type": "application/json",
                                "Authorization": "Bearer \(apiKey)"
                            ], timeoutSeconds: 10,
                            completion: {(response, err) in
                do {
                    guard let response = response, err == nil else {
                        os_log(.info, log: log, "错误的响应: %{public}s", err!.localizedDescription)
                        return
                    }
                    let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: response)
                    completion(result.choices[0].message.content)
                } catch {
                    os_log(.info, log: log, "未知错误: %{public}s", error.localizedDescription)
                }
            })
            NSLog("ddd")
        } catch {
            print("Error decoding JSON: \(error)")
        }
        
    }
}

struct ChatRequest: Codable {
    let model: String
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case messages
    }
    
    struct Message: Codable {
        let role: String
        let content: String

        enum CodingKeys: String, CodingKey {
            case role
            case content
        }
    }
}




struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    let object: String
    let usage: Usage
    let created: Int
    let systemFingerprint: String?
    let model: String
    let id: String

    enum CodingKeys: String, CodingKey {
        case choices
        case object
        case usage
        case created = "created"
        case systemFingerprint = "system_fingerprint"
        case model
        case id
    }
    
    struct Choice: Codable{
        let message: Message
        let finishReason: String
        let index: Int
        let logProbs: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
            case index
            case logProbs = "logprobs"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}


