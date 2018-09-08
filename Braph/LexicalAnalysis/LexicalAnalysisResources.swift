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
        "I" : .accept(QKeyWord(type: [.int, .intaractive], count: 1), .identifier("I")),
        "D" : .accept(QKeyWord(type: [.double], count: 1), .identifier("D")),
        "S" : .accept(QKeyWord(type: [.string], count: 1), .identifier("S")),
        "v" : .accept(QKeyWord(type: [.`var`], count: 1), .identifier("v")),
        "l" : .accept(QKeyWord(type: [.`let`], count: 1), .identifier("l")),
        " " : .accept(QForSeparator(), .separator),
        "=" : .accept(QForSymbol(), .symbol("=")),
        ":" : .accept(QForSymbol(), .symbol(".")),
        "," : .accept(QForSymbol(), .symbol(",")),
        "{" : .accept(QForSymbol(), .symbol("{")),
        "}" : .accept(QForSymbol(), .symbol("}")),
    ]
    
    static let notAcceptableCharsAsIndet: [Character] = [
        " ", ":", ",", ".", "{", "}", "="
    ]
    
    static let detectingKeyWord: [QKeyWord.DetectingType: (string: String, token: Token.KeyWordType)] = [
        .int : ("Int", .type),
        .intaractive: ("Intaractive", .type),
        .double : ("Double", .type),
        .string : ("String", .type),
        .`var` : ("var", .define),
        .`let` : ("let", .define)
    ]
}
