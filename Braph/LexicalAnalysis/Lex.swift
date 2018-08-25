//
//  Lex.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

enum KeyWordType {
    case type
}

enum OperantType {
    case Plus
}

enum LiteralType {
    case int
}

enum Lex {
    case keyword(KeyWordType, String)
    case operant(OperantType,String)
    case litral(String)
    case separator(String)
    case identifier(String)
    case space
}



class Lexs {
    static func indetifier(indetifier: String) -> Lex {
        return .identifier(indetifier)
    }
    
    static func space() -> Lex {
        return .space
    }
}

