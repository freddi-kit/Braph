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

protocol QDetetingKeyWord {
    associatedtype DetectingType
    init(type: DetectingType, count: Int)
    var type: DetectingType { get }
    var count: Int { get }
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
    
    class QForType: Q, QDetetingKeyWord {
        
        required init(type: DetectingType, count: Int) {
            self.type = type
            self.count = count
        }
        
        enum DetectingType {
            case int
            case double
        }
        let type: DetectingType
        let count: Int
        
    }
    
    class QForDefine: Q, QDetetingKeyWord {
        
        required init(type: DetectingType, count: Int) {
            self.type = type
            self.count = count
        }
        
        enum DetectingType {
            case `var`
            case `let`
        }
        let type: DetectingType
        let count: Int
        
    }
    
    class QForIndetifier: Q {
    }
    
    // MARK: オートマトンチェッカー
    
    private let nextQandStatusFromFirstString:[String: Status] = [
        " " : .accept(QForSeparator(),.separator),
        "I" : .accept(QForType(type: .int, count: 1),.identifier("I")),
        "D" : .accept(QForType(type: .double, count: 1),.identifier("D")),
        "v" : .accept(QForDefine(type: .`var`, count: 1),.identifier("v")),
        "l" : .accept(QForDefine(type: .`let`, count: 1),.identifier("l")),
    ]
    private let bookedCharacter: [Character] = [
        " ", ":", ",", ".", "{", "}", "="
    ]
    
    private let detectTypeFromQForType: [QForType.DetectingType: String] = [
        .int : "Int",
        .double: "Double"
    ]
    
    private let detectTypeFromQForDefine: [QForDefine.DetectingType: String] = [
        .`var`: "var",
        .`let`: "let"
    ]
    
    private func automataChecker(_ q: Q, _ input: [Character]) -> Status {
        switch q {
        // 初期状態
        case _ as QForStarter:
            if let result = nextQandStatusFromFirstString[String(input)] {
                return result
            }
            return .accept(QForIndetifier(),.identifier(String(input)))
        // 型キーワードを検出するかもしれない状態
        case let q as QForType:
            let type = q.type
            let nowCount = q.count
            
            guard let checkingTypeString = detectTypeFromQForType[type] else {
                return .undefined
            }

            let checkingTypeCharacters = Array(checkingTypeString)
            
            if input.last == checkingTypeCharacters[nowCount] {
                if input.count == checkingTypeCharacters.count {
                    return .accept(QForIndetifier(),.keyword(.type, String(input)))
                }
                return .accept(QForType(type: type, count: nowCount+1),.identifier(String(input)))
            }
            return .undefined
        // 宣言キーワードを検出するかもしれない状態
        case let q as QForDefine:
            let type = q.type
            let nowCount = q.count
            
            guard let checkingTypeString = detectTypeFromQForDefine[type] else {
                return .undefined
            }
            
            let checkingTypeCharacters = Array(checkingTypeString)
            
            if input.last == checkingTypeCharacters[nowCount] {
                if input.count == checkingTypeCharacters.count {
                    return .accept(QForIndetifier(),.keyword(.define, String(input)))
                }
                return .accept(QForDefine(type: type, count: nowCount+1),.identifier(String(input)))
            }
            return .undefined
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

