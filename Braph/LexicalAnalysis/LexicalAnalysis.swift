//
//  LexicalAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

protocol Q {
}

class LexicalAnalysis {
    
    typealias TokenSequence = [Token]
   
    // MARK : Public Functions
    
    /// Lexical Analysis
    public func analysis(input stringForAnalysis: String) -> TokenSequence? {
        var resultTokenSequence: TokenSequence = []
        var startIndex = 0, nowIndex = 0
        var nowQ: Q = QForStarter()
        var lastAcceptedIndexAndToken:(Int, Token)? = nil
        
        while nowIndex < stringForAnalysis.count {
            let subStringForAnalysis:[Character] = Array(stringForAnalysis)[startIndex...nowIndex].map { $0 }
            let status = automataChecker(nowQ, subStringForAnalysis)
    
            switch status {
            case .undefined:
                guard let nowLastAcceptIndexAndLex = lastAcceptedIndexAndToken else {
                    return nil
                }
                startIndex = nowLastAcceptIndexAndLex.0
                nowIndex = nowLastAcceptIndexAndLex.0 - 1
                resultTokenSequence.append(nowLastAcceptIndexAndLex.1)
                lastAcceptedIndexAndToken = nil
                nowQ = QForStarter()
            case let .accept(qFromAutomater, token):
                if nowIndex + 1 == stringForAnalysis.count {
                    resultTokenSequence.append(token)
                    return resultTokenSequence
                }
                lastAcceptedIndexAndToken = (nowIndex + 1, token)
                nowQ = qFromAutomater
            case let .normal(qFromAutomater):
                nowQ = qFromAutomater
            default:
                break;
            }
            nowIndex += 1
        }
        
        return resultTokenSequence
    }
    
    // MARK: Status
    
    enum Status {
        case start(Q)
        case normal(Q)
        case accept(Q, Token)
        case undefined
    }
    
    // MARK: Q
    
    class QForStarter: Q {
    }
    
    class QForSeparator: Q {
    }
    
    class QForDetetingKeyWord: Q {
        
        required init(type: [DetectingType], count: Int) {
            self.type = type
            self.count = count
        }
        
        enum DetectingType {
            case int
            case double
            case string
            case intaractive
            case `var`
            case `let`
        }
        let type: [DetectingType]
        let count: Int
        
    }
    
    class QForIndetifier: Q {
    }
    
    // MARK: オートマトンチェッカー
    
    private let nextQandStatusFromFirstString:[String: Status] = [
        " " : .accept(QForSeparator(), .separator),
        "I" : .accept(QForDetetingKeyWord(type: [.int, .intaractive], count: 1), .identifier("I")),
        "D" : .accept(QForDetetingKeyWord(type: [.double], count: 1), .identifier("D")),
        "S" : .accept(QForDetetingKeyWord(type: [.string], count: 1), .identifier("S")),
        "v" : .accept(QForDetetingKeyWord(type: [.`var`], count: 1), .identifier("v")),
        "l" : .accept(QForDetetingKeyWord(type: [.`let`], count: 1), .identifier("l")),
    ]
    
    private let bookedCharacter: [Character] = [
        " ", ":", ",", ".", "{", "}", "="
    ]
    
    private let detectingKeyWord: [QForDetetingKeyWord.DetectingType: String] = [
        .int : "Int",
        .intaractive: "Intaractive",
        .double : "Double",
        .string : "String",
        .`var` : "var",
        .`let` : "let"
    ]
    
    private func automataChecker(_ q: Q, _ input: [Character]) -> Status {
        let inputToString = String(input)
        switch q {
        // 初期状態
        case _ as QForStarter:
            if let result = nextQandStatusFromFirstString[String(input)] {
                return result
            }
            return .accept(QForIndetifier(),.identifier(String(input)))
        // キーワードを検出するかもしれない状態
        case let q as QForDetetingKeyWord:
            let type = q.type
            let nowCount = q.count
            
            guard let nowType = type.first, let checkingTypeString = detectingKeyWord[nowType], input.last != " " else {
                return .undefined
            }

            let checkingTypeCharacters = checkingTypeString.map { $0 } 
            
            if input.last == checkingTypeCharacters[nowCount] {
                if input.count == checkingTypeCharacters.count {
                    if q.type.count == 1 {
                        return .accept(QForIndetifier(), .keyword(.type, inputToString))
                    }
                    return .accept(QForDetetingKeyWord(type: q.type.suffix(from: 1).map{ $0 }, count: input.count),.keyword(.type, inputToString))
                }
                return .accept(QForDetetingKeyWord(type: type, count: nowCount+1),.identifier(inputToString))
            }
            return .accept(QForIndetifier(),.identifier(inputToString))
        // セパレータの状態
        case _ as QForSeparator:
            if input.last == " " {
                return .accept(QForSeparator(),.separator)
            }
            return .undefined
        // 識別子の状態
        case _ as QForIndetifier:
            if let inputLastCharacter = input.last, bookedCharacter.contains(inputLastCharacter) {
                return .undefined
            }
            return .accept(QForIndetifier(),.identifier(String(input)))
        default:
            return .undefined
        }
    }
}

