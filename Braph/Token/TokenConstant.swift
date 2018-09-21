//
//  TokenConstant.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/20.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

// いわゆる非終端記号
enum TokenConstants: Int, Token {
    case expr
    case term
    case factor
    case declaration
    case function
    case arg
    case initializer
    case `return`
    case statement
    
    // For Extend Syntax
    case start
    
    public func isStart() -> Bool {
        switch self {
        case .expr, .declaration:
            return true
        default:
            return false
        }
    }
}
