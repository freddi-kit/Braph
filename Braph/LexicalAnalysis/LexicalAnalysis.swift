//
//  LexicalAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

class LexicalAnalysis {
    
    // MARK: Nested Types
    
    // なんでこんなことやったかよくわからんけど、放置
    typealias TokenSequence = [Token]
    
    enum Status {
        case start(Q)
        case normal(Q, Token)
        case accept(Q, Token)
        case undefined
    }
    
    // MARK : Public Functions
    
    /// 字句解析
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
                if nowIndex + 1 == stringForAnalysis.count && !token.isSeparator() {
                    resultTokenSequence.append(token)
                }
                lastAcceptedIndexAndToken = (nowIndex + 1, token)
                nowQ = qFromAutomater
            case let .normal(qFromAutomater, _):
                if nowIndex + 1 == stringForAnalysis.count {
                    return nil
                }
                nowQ = qFromAutomater
            default:
                break;
            }
            nowIndex += 1
        }
        
        resultTokenSequence.append(.end)
        
        return resultTokenSequence
    }

    // MARK: 字句解析のオートマトンのチェック
    
    private func automataChecker(_ q: Q, _ input: [Character]) -> Status {
        // 一番先頭の文字
        guard let inputFirstCharacter = input.first,
            let inputLastCharacter = input.last else {
            return .accept(QForSeparator(),.separator)
        }
        
        let inputToString = String(input)
        switch q {
        // 状態: 初期
        case _ as QForStarter:
            // 初期状態から次の検知状態の探索
            if let result = LexicalAnalysisResources.nextStatusFromFirstChara[inputFirstCharacter] {
                return result
            }
            
            if let result = LexicalAnalysisResources.literalChecker(input: inputFirstCharacter) {
                return result
            }
            
            // それ以外の場合、識別子検知状態に投げる
            return .accept(
                QForIndetifier(),
                .identifier(String(input))
            )
        // キーワードを検出するかもしれない状態
        case let q as QKeyWord:
            let type = q.type       // いま撮ろうとしているキーワードの種類（優先度順の配列）
            let nowCount = q.count  // 現在の文字列の長さ
            
            guard let nowType = type.first,                             // 撮ろうとしているキーワードがある
                let nowDetectingKeyWord = LexicalAnalysisResources.detectingKeyWord[nowType],    // キーワードがdetectingKeyWordに登録済み
                !LexicalAnalysisResources.notAcceptableCharsAsIndet.contains(inputLastCharacter) // 最後の文字は識別子に含められる文字である
                else {
                return .undefined
            }
            
            // 今チェックしているキーワードのString
            let checkingTypeCharacters = Array(nowDetectingKeyWord.string)
            
            // 文字列が今の所一致しているかどうか
            if input.last == checkingTypeCharacters[nowCount] {
                // すべて一致したとき
                if input.count == checkingTypeCharacters.count {
                    // 現在の文字列で検知すべきキーワードがもう無い
                    if q.type.count == 1 {
                        return .accept(
                            QForIndetifier(),
                            .keyword(nowDetectingKeyWord.token, inputToString)
                        )
                    }
                    // まだある
                    return .accept(
                        QKeyWord(
                            typeStack: q.type.suffix(from: 1).map{ $0 },
                            count: input.count
                        ),
                        .keyword(nowDetectingKeyWord.token, inputToString)
                    )
                }
                return .accept(
                    QKeyWord(
                        typeStack: type,
                        count: nowCount+1),
                    .identifier(inputToString)
                )
            }
            
            // もし、キーワードに合致しない場合は識別子として取る
            return .accept(
                QForIndetifier(),
                .identifier(inputToString)
            )
        // 状態: 空白
        case _ as QForSeparator:
            // 連続する空白は一つのセパレータとしてとること
            if input.last == " " {
                return .accept(QForSeparator(),.separator)
            }
            return .undefined
        // 状態: 識別子
        case _ as QForIndetifier:
            // もし末尾に記号がある場合、undefinedにする
            if LexicalAnalysisResources.notAcceptableCharsAsIndet.contains(inputLastCharacter) {
                return .undefined
            }
            
            // それ以外の場合は識別子として取る
            return .accept(
                QForIndetifier(),
                .identifier(inputToString)
            )
        // 状態: 数値リテラル
        case let q as QForNumericLiteral:
            if inputLastCharacter == "." && !(q.type == .Double) {
                return .accept(QForNumericLiteral(type: .Double), .literal(.Double, inputToString))
            }
            if LexicalAnalysisResources.numericLiterals.contains(inputLastCharacter) {
                let typeForAccept: Token.LiteralType = (q.type == .Double) ? .Double : .Int
                return .accept(QForNumericLiteral(type: typeForAccept), .literal(typeForAccept, inputToString))
            }
            return .undefined
        // 状態: 文字列リテラル
        case _ as QForStringLiteral:
            if LexicalAnalysisResources.stringLiterals.contains(inputLastCharacter),
                inputFirstCharacter == inputLastCharacter {
                return .accept(QForDeadStatus(), .literal(.String, inputToString))
            }
            return .normal(QForStringLiteral(), .literal(.String, inputToString))
        // 状態: 未定義
        default:
            return .undefined
        }
    }
}

