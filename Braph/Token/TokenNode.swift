//
//  Lex.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

// なんでこんなことやったかよくわからんけど、放置
typealias TokenSequence = [TokenNode]

// 記号（トークン）のプロトコル
protocol Token {
}

// いわゆる終端記号
enum TokenNode: Token {
    
    // MARK: Token Types
    
    // キーワードの特定
    enum KeyWordType {
        case type
        case define
        case `return`
    }
    
    // オペラントの特定
    enum OperantType {
        case plus
        case time
    }
    
    // リテラルの特定
    enum LiteralType {
        case `Int`
        case `Double`
        case `String`
    }
    
    // MARK : Tokens
    
    // 終端記号、Optional = 何でも入ると基本扱う予定
    case keyword(KeyWordType, String?)
    case operant(OperantType?, String?)
    case literal(LiteralType?, String?)
    case identifier(String?)
    case symbol(String)
    case parenthesis(String?)
    case separator
    case end
    case `$`
    
    // これはセパレータですか？
    public func isSeparator() -> Bool {
        switch self {
        case .separator:
            return true
        default:
            return false
        }
    }
}

extension Set {
    static func += (lhs: inout Set<Element>, rhs: [Element]) {
        for value in rhs {
            lhs.insert(value)
        }
    }
    static func += (lhs: inout Set<Element>, rhs: Set<Element>) {
        for value in rhs {
            lhs.insert(value)
        }
    }
}
