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
        inputHandler.isEnMode = true
        
        let _ = inputHandler.handlerInput(.lower(char: "t"))
        var text = inputHandler.getCompsingText()
        assert(text == "t")
        
        let _ = inputHandler.handlerInput(.lower(char: "r"))
        text = inputHandler.getCompsingText()
        assert(text == "tr")
        
        let _ = inputHandler.handlerInput(.lower(char: "a"))
        text = inputHandler.getCompsingText()
        assert(text == "tra")

        let _ = inputHandler.handlerInput(.lower(char: "n"))
        text = inputHandler.getCompsingText()
        assert(text == "tran")

        let _ = inputHandler.handlerInput(.lower(char: "s"))
        text = inputHandler.getCompsingText()
        assert(text == "trans")

        let _ = inputHandler.handlerInput(.lower(char: "B"))
        text = inputHandler.getCompsingText()
        assert(text == "transB")
        
        let _ = inputHandler.handlerInput(.lower(char: "t"))
        text = inputHandler.getCompsingText()
        assert(text == "transBt")
        
        let _ = inputHandler.handlerInput(.lower(char: "n"))
        text = inputHandler.getCompsingText()
        assert(text == "transBtn")
        
        inputHandler.isEnMode = false
        let _ = inputHandler.handlerInput(.lower(char: "x"))
        text = inputHandler.getCompsingText()
        assert(text == "transBtnx")
    }
    
    func testExample3() throws {
        
        let inputHandler = InputHandler()
        inputHandler.loadDict()
//        inputHandler.isEnMode = true
        
        let _ = inputHandler.handlerInput(.lower(char: "w"))
        let _ = inputHandler.handlerInput(.lower(char: "q"))
        let _ = inputHandler.handlerInput(.lower(char: "v"))
        let _ = inputHandler.handlerInput(.lower(char: "b"))
        let _ = inputHandler.makeCadidates()
        let _ = inputHandler.handlerInput(.space)
        var text = inputHandler.getCompsingText()
        assert(text == "你好")

        let _ = inputHandler.handlerInput(.other(char: ","))
        text = inputHandler.getCompsingText()
        assert(text == "你好，")
        let _ = inputHandler.handlerInput(.lower(char: "d"))
        let _ = inputHandler.handlerInput(.backspace)
        let _ = inputHandler.handlerInput(.lower(char: "d"))
        let cads = inputHandler.makeCadidates()
        assert(!cads.isEmpty)
    }
}
