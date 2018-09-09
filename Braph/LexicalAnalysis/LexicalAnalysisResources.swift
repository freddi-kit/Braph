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
    static let nextStatusFromFirstChara:[Character: LexicalAnalysis.Status] = [
        "I" : .accept(QKeyWord(typeStack: [.int, .intaractive], count: 1), .identifier("I")),
        "D" : .accept(QKeyWord(typeStack: [.double], count: 1), .identifier("D")),
        "S" : .accept(QKeyWord(typeStack: [.string], count: 1), .identifier("S")),
        "v" : .accept(QKeyWord(typeStack: [.var], count: 1), .identifier("v")),
        "l" : .accept(QKeyWord(typeStack: [.let], count: 1), .identifier("l")),
        "f" : .accept(QKeyWord(typeStack: [.func], count: 1), .identifier("l")),
        "r" : .accept(QKeyWord(typeStack: [.return], count: 1), .identifier("r")),
        " " : .accept(QForSeparator(), .separator),
        "=" : .accept(QForSymbol(), .symbol("=")),
        ":" : .accept(QForSymbol(), .symbol(":")),
        "," : .accept(QForSymbol(), .symbol(",")),
        "{" : .accept(QForSymbol(), .symbol("{")),
        "}" : .accept(QForSymbol(), .symbol("}")),
        "+" : .accept(QForSymbol(), .operant(.plus, "+")),
        "-" : .accept(QForSymbol(), .operant(.minus, "-"))
    ]
    
    static let notAcceptableCharsAsIndet: [Character] = [
        " ", ":", ",", ".", "{", "}", "=", "+", "-"
    ]
    
    static let detectingKeyWord: [QKeyWord.DetectingType: (string: String, token: Token.KeyWordType)] = [
        .int : ("Int", .type),
        .intaractive: ("Intaractive", .type),
        .double : ("Double", .type),
        .string : ("String", .type),
        .var : ("var", .define),
        .let : ("let", .define),
        .func : ("func", .define),
        .return : ("return", .return)
    ]
    
    static let numericLiterals: [Character] = Array("0123456789")
    
    static let stringLiterals: [Character] = [
        "\"", "\'"
    ]
    
    static func literalChecker(input: Character) -> LexicalAnalysis.Status? {
        if numericLiterals.contains(input) {
            return .accept(QForNumericLiteral(type: .int), .literal(.int, String(input)))
        } else if stringLiterals.contains(input) {
            return .normal(QForStringLiteral(), .literal(.string, String(input)))
        }
        return nil
    }
}
