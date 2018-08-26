//
//  LexicalAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

typealias TokenSeqence = [Token]

func lexicalAnalysis(_ input: String) -> TokenSeqence? {
    var result: TokenSeqence = []
    var startIndex = 0, index = 0, q = 0
    var lastAcceptIndexAndLex:(Int, Token)? = nil
    
    let inputCharacters = Array(input)
    
    while index < inputCharacters.count {
        let inputFrom = input.index(input.startIndex, offsetBy: startIndex)
        let inputTo = input.index(input.startIndex, offsetBy: index)
        
        let stage = automataChecker(q, String(input[inputFrom...inputTo]))

        switch stage {
        case .undefined:
            guard let nowLastAcceptIndexAndLex = lastAcceptIndexAndLex else {
                return nil
            }
            startIndex = nowLastAcceptIndexAndLex.0
            index = nowLastAcceptIndexAndLex.0 - 1
            result.append(nowLastAcceptIndexAndLex.1)
            lastAcceptIndexAndLex = nil
            q = 0
        case let .accept(qFromAutomater, token):
            if index + 1 == inputCharacters.count {
                result.append(token)
                return result
            }
            lastAcceptIndexAndLex = (index + 1, token)
            q = qFromAutomater
        case let .normal(qFromAutomater):
            q = qFromAutomater
        default:
            break;
        }
        index += 1
    }
    
    return result
}
