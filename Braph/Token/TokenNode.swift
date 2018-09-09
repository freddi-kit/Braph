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

protocol Token {
}

enum TokenNode: Token {
    
    // MARK: Token Types
    
    enum KeyWordType {
        case type
        case define
        case `return`
    }
    
    enum OperantType {
        case plus
        case minus
    }
    
    enum LiteralType {
        case `Int`
        case `Double`
        case `String`
    }
    
    // MARK : Tokens
    
    case keyword(KeyWordType, String)
    case operant(OperantType, String)
    case literal(LiteralType, String)
    case identifier(String)
    case symbol(String)
    case parenthesis(String)
    case separator
    case end
    
    func isSeparator() -> Bool {
        switch self {
        case .separator:
            return true
        default:
            return false
        }
    }
}

class TokenTree: Token {
    
}