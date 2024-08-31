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
        let inputProcesser = InputProcesser()
        inputProcesser.loadDict()
        
        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "a")
        assert(inputProcesser.cursorPos == 1)
        assert(inputProcesser.codeCount == 1)

        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "aa")
        assert(inputProcesser.cursorPos == 2)
        assert(inputProcesser.codeCount == 2)

        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "aaa")
        assert(inputProcesser.cursorPos == 3)
        assert(inputProcesser.codeCount == 3)

        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "aaaa")
        assert(inputProcesser.cursorPos == 4)
        assert(inputProcesser.codeCount == 4)

        let _ = inputProcesser.makeCadidates()

        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "工a")
        assert(inputProcesser.cursorPos == 2)
        assert(inputProcesser.codeCount == 1)

        let _ = inputProcesser.processInput(.left)
        assert(inputProcesser.composingString == "工a")
        assert(inputProcesser.cursorPos == 1)
        assert(inputProcesser.codeCount == 0)

        let _ = inputProcesser.processInput(.right)
        assert(inputProcesser.composingString == "工a")
        assert(inputProcesser.cursorPos == 2)
        assert(inputProcesser.codeCount == 0)

        let _ = inputProcesser.processInput(.enter)
        assert(inputProcesser.composingString == "工a")
        assert(inputProcesser.cursorPos == 2)
        assert(inputProcesser.codeCount == 0)

        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "工aa")
        assert(inputProcesser.cursorPos == 3)
        assert(inputProcesser.codeCount == 1)

        let _ = inputProcesser.makeCadidates()
        
        let _ = inputProcesser.processInput(.space)
        assert(inputProcesser.composingString == "工a工")
        assert(inputProcesser.cursorPos == 3)
        assert(inputProcesser.codeCount == 0)

        let _ = inputProcesser.processInput(.backspace)
        assert(inputProcesser.composingString == "工a")
        assert(inputProcesser.cursorPos == 2)
        assert(inputProcesser.codeCount == 0)
        
        let _ = inputProcesser.processInput(.backspace)
        assert(inputProcesser.composingString == "工")
        assert(inputProcesser.cursorPos == 1)
        assert(inputProcesser.codeCount == 0)

        let _ = inputProcesser.processInput(.backspace)
        assert(inputProcesser.composingString == "")
        assert(inputProcesser.cursorPos == 0)
        assert(inputProcesser.codeCount == 0)
        
        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "a")
        assert(inputProcesser.cursorPos == 1)
        assert(inputProcesser.codeCount == 1)
        
        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "aa")
        assert(inputProcesser.cursorPos == 2)
        assert(inputProcesser.codeCount == 2)
        
        
        let _ = inputProcesser.makeCadidates()
        
        let _ = inputProcesser.processInput(.space)
        assert(inputProcesser.composingString == "式")
        assert(inputProcesser.cursorPos == 1)
        assert(inputProcesser.codeCount == 0)
        
        let _ = inputProcesser.processInput(.left)
        assert(inputProcesser.composingString == "式")
        assert(inputProcesser.cursorPos == 0)
        assert(inputProcesser.codeCount == 0)

        
        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "a式")
        assert(inputProcesser.cursorPos == 1)
        assert(inputProcesser.codeCount == 1)
        
        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "aa式")
        assert(inputProcesser.cursorPos == 2)
        assert(inputProcesser.codeCount == 2)
        
        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "aaa式")
        assert(inputProcesser.cursorPos == 3)
        assert(inputProcesser.codeCount == 3)
        
        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "aaaa式")
        assert(inputProcesser.cursorPos == 4)
        assert(inputProcesser.codeCount == 4)
        
        
        let _ = inputProcesser.makeCadidates()
        let _ = inputProcesser.processInput(.lower(char: "a"))
        assert(inputProcesser.composingString == "工a式")
        assert(inputProcesser.cursorPos == 2)
        assert(inputProcesser.codeCount == 1)
        
        let _ = inputProcesser.processInput(.backspace)
        assert(inputProcesser.composingString == "工式")
        assert(inputProcesser.cursorPos == 1)
        assert(inputProcesser.codeCount == 0)
        
        let _ = inputProcesser.processInput(.backspace)
        assert(inputProcesser.composingString == "式")
        assert(inputProcesser.cursorPos == 0)
        assert(inputProcesser.codeCount == 0)
        
        let _ = inputProcesser.makeCadidates()

    }
    
}
