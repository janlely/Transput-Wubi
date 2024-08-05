//
//  InputState.swift
//  Transput
//
//  Created by jin junjie on 2024/8/5.
//

import Foundation

enum InputState {
    case start
    case start2
//    case toBeContinue
    case inputing //输入中
    case manuallySeleting //手动选择候选词
    case autoSelecting //自动选择候选词
}


enum CharType {
    case lower(char: Character) //小写字母
    case number(num: Character) //数字
    case other(char: Character) //其他可见字符：标点，大写字母
    case space
    case backspace
    case enter
}

