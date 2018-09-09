//
//  LexicalAnalysisResources.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/09.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

// TODO: 自動生成スクリプトの作成

class LexicalAnalysisResources {
    static public let nextStatusFromFirstChara:[Character: LexicalAnalysis.Status] = [
        "I" : .accept(QKeyWord(typeStack: [.Int, .Intaractive], count: 1), .identifier("I")),
        "D" : .accept(QKeyWord(typeStack: [.Double], count: 1), .identifier("D")),
        "S" : .accept(QKeyWord(typeStack: [.String], count: 1), .identifier("S")),
        "v" : .accept(QKeyWord(typeStack: [.var], count: 1), .identifier("v")),
        "l" : .accept(QKeyWord(typeStack: [.let], count: 1), .identifier("l")),
        "f" : .accept(QKeyWord(typeStack: [.func], count: 1), .identifier("l")),
        "r" : .accept(QKeyWord(typeStack: [.return], count: 1), .identifier("r")),
        " " : .accept(QForSeparator(), .separator),
        "=" : .accept(QForSymbol(), .symbol("=")),
        ":" : .accept(QForSymbol(), .symbol(":")),
        "," : .accept(QForSymbol(), .symbol(",")),
        ";" : .accept(QForSymbol(), .end),
        "{" : .accept(QForSymbol(), .parenthesis("{")),
        "}" : .accept(QForSymbol(), .parenthesis("}")),
        "(" : .accept(QForSymbol(), .parenthesis("(")),
        ")" : .accept(QForSymbol(), .parenthesis(")")),
        "+" : .accept(QForSymbol(), .operant(.plus, "+")),
        "-" : .accept(QForSymbol(), .operant(.minus, "-"))
    ]
    
    static public let notAcceptableCharsAsIndet: [Character] = Array(" :;,.{}()=+-")
    
    static public let detectingKeyWord: [QKeyWord.DetectingToken: (string: String, token: TokenNode.KeyWordType)] = [
        .Int : ("Int", .type),
        .Intaractive: ("Intaractive", .type),
        .Double : ("Double", .type),
        .String : ("String", .type),
        .var : ("var", .define),
        .let : ("let", .define),
        .func : ("func", .define),
        .return : ("return", .return)
    ]
    
    static public let numericLiterals: [Character] = Array("0123456789")
    
    static public let stringLiterals: [Character] = [
        "\"", "\'"
    ]
    
    static public func literalChecker(input: Character) -> LexicalAnalysis.Status? {
        if numericLiterals.contains(input) {
            return .accept(QForNumericLiteral(type: .Int), .literal(.Int, String(input)))
        } else if stringLiterals.contains(input) {
            return .normal(QForStringLiteral(), .literal(.String, String(input)))
        }
        return nil
    }
}
