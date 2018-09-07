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
        var nowQ: Q = QForStarter.checkingStart
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
                nowQ = QForStarter.checkingStart
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
    
    enum QForStarter: Q {
        case checkingStart
    }
    
    class QForSeparator: Q {
    }
    
    enum QForType: Q {
        enum type {
            case int
            case double
        }
        case checking(type, Int)
    }
    
    enum QForIndetifier: Q {
        case checkingIndentifier
    }
    
    // MARK: オートマトンチェッカー
    
    private let detectQFromInitial:[String: Status] = [
        " " : .accept(QForSeparator(),.separator),
        "I" : .accept(QForType.checking(.int, 1),.identifier("I")),
        "D" : .accept(QForType.checking(.double, 1),.identifier("D"))
    ]
    private let bookedCharacter: [Character] = [
        " ", ":", ",", ".", "{", "}", "="
    ]
    
    private let detectTypeFromQForType: [QForType.type: String] = [
        .int : "Int",
        .double: "Double"
    ]
    
    private func automataChecker(_ q: Q, _ input: [Character]) -> Status {
        switch q {
        // 初期状態
        case _ as QForStarter:
            if let result = detectQFromInitial[String(input)] {
                return result
            }
            return .accept(QForIndetifier.checkingIndentifier,.identifier(String(input)))
        // 型キーワードを検出するかもしれない状態
        case let q as QForType:
            switch q {
            case .checking(let type, let nowStage):
                guard let checkingTypeString = detectTypeFromQForType[type] else {
                    return .undefined
                }
                let checkingTypeCharacters = Array(checkingTypeString)
                if input.last == checkingTypeCharacters[nowStage] {
                    if input.count == checkingTypeCharacters.count {
                        return .accept(QForIndetifier.checkingIndentifier,.keyword(.type, String(input)))
                    }
                    return .accept(QForType.checking(type, nowStage+1),.identifier(String(input)))
                }
                return .undefined
            }
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
            return .accept(QForIndetifier.checkingIndentifier,.identifier(String(input)))
        default:
            return .undefined
        }
    }
}

