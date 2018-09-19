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
    case define
    case function
    case arg
    
    public func isStart() -> Bool {
        switch self {
        case .expr, .define:
            return true
        default:
            return false
        }
    }
}
