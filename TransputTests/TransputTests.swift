//
//  TransputTests.swift
//  TransputTests
//
//  Created by β α on 2021/09/07.
//

import XCTest
@testable import Transput_Wubi

class TransputTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample1() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let inputHandler = InputHandler()
        inputHandler.loadDict()
        
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        var text = inputHandler.getCompsingText()
        assert(text == "a")
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        text = inputHandler.getCompsingText()
        assert(text == "aa")
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        text = inputHandler.getCompsingText()
        assert(text == "aaa")
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        text = inputHandler.getCompsingText()
        assert(text == "aaaa")
        let _ = inputHandler.makeCadidates()
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        assert(inputHandler.getCompsingText() == "工a")
        
        let _ = inputHandler.handlerInput(.backspace)
        text = inputHandler.getCompsingText()
        assert(inputHandler.getCompsingText() == "aaaa")

        let _ = inputHandler.makeCadidates()
        let _ = inputHandler.handlerInput(.space)
        assert(inputHandler.getCompsingText() == "工")

        let _ = inputHandler.handlerInput(.backspace)
        text = inputHandler.getCompsingText()
        assert(text == "")

        let _ = inputHandler.handlerInput(.lower(char: "a"))
        text = inputHandler.getCompsingText()
        assert(text == "a")

        let _ = inputHandler.handlerInput(.space)
        text = inputHandler.getCompsingText()
        assert(text == "工")
        
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        text = inputHandler.getCompsingText()
        assert(text == "工a")

        let _ = inputHandler.handlerInput(.backspace)
        text = inputHandler.getCompsingText()
        assert(text == "工")
        
        let _ = inputHandler.handlerInput(.backspace)
        text = inputHandler.getCompsingText()
        assert(text == "")

        
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        text = inputHandler.getCompsingText()
        assert(text == "a")

        let _ = inputHandler.handlerInput(.space)
        text = inputHandler.getCompsingText()
        assert(text == "工")
        
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        text = inputHandler.getCompsingText()
        assert(text == "工a")

        let _ = inputHandler.handlerInput(.backspace)
        text = inputHandler.getCompsingText()
        assert(text == "工")
        
        let _ = inputHandler.handlerInput(.backspace)
        text = inputHandler.getCompsingText()
        assert(text == "")
    }

    
    func testExample2() throws {
        
        let inputHandler = InputHandler()
        inputHandler.loadDict()
        
        let _ = inputHandler.handlerInput(.lower(char: "w"))
        var text = inputHandler.getCompsingText()
        assert(text == "w")
        
        let _ = inputHandler.handlerInput(.lower(char: "q"))
        text = inputHandler.getCompsingText()
        assert(text == "wq")
        
        let _ = inputHandler.handlerInput(.other(char: "，"))
        text = inputHandler.getCompsingText()
        assert(text == "你，")
        
        

    }
}
