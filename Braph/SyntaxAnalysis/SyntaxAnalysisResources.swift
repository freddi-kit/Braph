//
//  SyntaxAnalysisResources.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/20.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation


class SyntaxAnalysisResources {
    
    // MARK: Constants
    
    // 文法の宣言
    public static let definedSyntaxs: [TokenConstants: [SyntaxTree]] = [
        .define : [
            .init([TokenNode.keyword(.define, nil), TokenNode.identifier(nil), TokenNode.symbol("="),  TokenConstants.expr])
        ],
        .expr : [
            .init([TokenConstants.expr, TokenNode.operant(.plus, nil), TokenConstants.term]),
            .init([TokenConstants.term])
        ],
        .term : [
            .init([TokenConstants.term, TokenNode.operant(.time, nil), TokenConstants.factor]),
            .init([TokenConstants.factor])
        ],
        .factor :  [
            .init([TokenNode.literal(nil, nil)]),
            .init([TokenNode.parenthesis("("), TokenConstants.expr, TokenNode.parenthesis(")")])
        ]
    ]
}

extension SyntaxAnalysisResources {
    
    // MARK: Functions

    /// First集合を求める
    public static func calcFirstUnion(token: Token) -> [TokenNode] {
        var resultTokens: Array<TokenNode> = []
        if let token = token as? TokenConstants, let rightTokensTrees = definedSyntaxs[token] {
            for rightTokensTree in rightTokensTrees {
                if let rightToken = rightTokensTree.nodes.first as? TokenConstants,
                    rightToken != token {
                    resultTokens += calcFirstUnion(token: rightToken)
                } else if let rightToken = rightTokensTree.nodes.first as? TokenNode  {
                    resultTokens += [rightToken]
                }
            }
        }
        else if let token = token as? TokenNode {
            resultTokens += [token]
        }
        return reduceSameElementFromTokenNodeUnion(array: resultTokens)
    }
    
    /// Follow集合を求める
    public static func calcFollowUnion(token: TokenConstants) -> Array<TokenNode> {
        var resultTokens: [TokenNode] = []
        if token.isStart() {
            resultTokens += [TokenNode.`$`]
        }
        for definedSyntaxKey in definedSyntaxs.keys {
            guard let tokenTrees = definedSyntaxs[definedSyntaxKey] else { continue }
            for tokenTree in tokenTrees {
                for index in 0..<tokenTree.nodes.count {
                    if let nodeToConstants = tokenTree.nodes[index] as? TokenConstants, nodeToConstants == token {
                        if index + 1 < tokenTree.nodes.count {
                            if let token = tokenTree.nodes[index + 1] as? TokenNode {
                                resultTokens += [token]
                            } else if let token = tokenTree.nodes[index + 1] as? TokenConstants {
                                resultTokens += calcFirstUnion(token: token)
                            }
                        }
                        if index == tokenTree.nodes.count - 1 {
                            resultTokens += calcFollowUnion(token: definedSyntaxKey)
                        }
                    }
                }
            }
        }
        return reduceSameElementFromTokenNodeUnion(array: resultTokens)
    }
    
    
    /// Closure集合を求める
    public static func calcClosureUnion(lhs: TokenConstants, rhs: [Token], point: Int) -> [(lhs: TokenConstants, rhs: [Token], point: Int)] {
        var resultUnion: [(lhs: TokenConstants, rhs: [Token], point: Int)] = []
        if point >= rhs.count {
            return resultUnion
        }
        resultUnion += [(lhs: lhs, rhs: rhs, point: point)]
        if let pointingConstants = rhs[point] as? TokenConstants,
            let sytaxes = definedSyntaxs[pointingConstants],
            pointingConstants != lhs {
            for syntax in sytaxes {
                resultUnion += calcClosureUnion(lhs: pointingConstants, rhs: syntax.nodes, point: 0)
            }
        }
        return resultUnion
    }
    
    /// Goto集合を求める
    public static func calcGotoUnion(i: [(lhs: TokenConstants, rhs: [Token], point: Int)], forcusToken: Token) -> [(lhs: TokenConstants, rhs: [Token], point: Int)] {
        var resultUnion: [(lhs: TokenConstants, rhs: [Token], point: Int)] = []
        return resultUnion
    }
    
    private static func reduceSameElementFromTokenNodeUnion(array: [TokenNode]) -> [TokenNode] {
        var result:[TokenNode] = []
        for element in array {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}



extension TokenNode: Equatable {
    // MARK: First、Follow向けの拡張
    
    static private func compareAndNilAsSame<E1: Equatable, E2: Equatable>(ll: E1?, lr: E2?, rl: E1?, rr: E2?) -> Bool {
        let isLvalueIsNull = (ll == nil || rl == nil)
        let isRvalueIsNull = (lr == nil || rr == nil)
        if isLvalueIsNull && isRvalueIsNull {
            return true
        }
        else if isLvalueIsNull {
            return lr == rr
        }
        return ll == rl
    }
    
    static func == (lhs: TokenNode, rhs: TokenNode) -> Bool {
        
        switch (lhs, rhs) {
        case (.keyword(let ll, let lr), .keyword(let rl, let rr)):
            return compareAndNilAsSame(ll: ll, lr: lr, rl: rl, rr: rr)
        case (.operant(let ll, let lr), .operant(let rl, let rr)):
            return compareAndNilAsSame(ll: ll, lr: lr, rl: rl, rr: rr)
        case (.literal(let ll, let lr), .literal(let rl, let rr)):
            return compareAndNilAsSame(ll: ll, lr: lr, rl: rl, rr: rr)
        case (.identifier(let l), .identifier(let r)):
            if l == nil || r == nil {
                return true
            } else {
                return l == r
            }
        case (.symbol(let l), .symbol(let r)):
            return l == r
        case (.parenthesis(let l), .parenthesis(let r)):
            return l == r
        case (.separator, .separator):
            return true
        case (.end, .end):
            return true
        case (.`$`, .`$`):
            return true
        default:
            return false
        }
    }
}

