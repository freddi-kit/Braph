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
    case assign
    case function
    case arg
    case initializer
    case `return`
    case statement
    
    // Extend Syntax For LR(1) analysis.
    case start
    
    // Test
    case S
    case A
    case E
    case T
    case U
    case V
}
