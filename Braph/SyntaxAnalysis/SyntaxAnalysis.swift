//
//  SyntaxAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/09.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

class SyntaxAnalysis {
    
    // MARK: Public functions
    public func analysis(input :[TokenNode]) -> SyntaxTree? {
        return nil
    }
}

// 構文木
class SyntaxTree: Token {
    
    // MARK: Neseted Type
    
    // いわゆる非終端記号
    enum TokenConstants: Int, Token {
        case start
        case exprDash
        case expr
        case term
        case factor
        case define
        case function
        case arg
    }
    
    // MARK: Initialization
    
    init(_ nodes: [Token]) {
        self.nodes = nodes
    }
    
    // MARK: Public Values
    
    public var nodes: [Token]
    
    // MARK: Constants
    
    // 文法の宣言
    public static let definedSyntaxs: [TokenConstants: [SyntaxTree]] = [
        .start : [
            .init([TokenConstants.expr]),
            .init([TokenConstants.define])
        ],
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
    public static func calcFollowUnion(token: TokenConstants, isStart: Bool = true) -> Array<TokenNode> {
        var resultTokens: Array<TokenNode> = []
        for definedSyntaxKey in definedSyntaxs.keys {
            if isStart {
                resultTokens += [TokenNode.`$`]
            }
            guard let tokenTrees = definedSyntaxs[definedSyntaxKey] else { continue }
            for tokenTree in tokenTrees {
                for index in 0..<tokenTree.nodes.count {
                    if let nodeToConstants = tokenTree.nodes[index] as? TokenConstants, nodeToConstants == token {
                        if index + 1 < tokenTree.nodes.count {
                            if let node = tokenTree.nodes[index + 1] as? TokenNode {
                                resultTokens += [node]
                            } else if let node = tokenTree.nodes[index + 1] as? TokenConstants {
                                resultTokens += calcFirstUnion(token: node)
                            }
                        }
                        if index == tokenTree.nodes.count - 1 {
                            resultTokens += calcFollowUnion(token: definedSyntaxKey, isStart: false)
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

// First、Follow向けの拡張
extension TokenNode: Equatable {
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

//// First、Follow向けの拡張
//extension TokenNode: Hashable {
//    // ○ね！！！！！！１
//    var hashValue: Int {
//        switch self {
//        case let .keyword(keyWord, _):
//            switch keyWord {
//            case .define:
//                return 0
//            case .return:
//                return 1
//            case .type:
//                return 2
//            }
//        case let .operant(operant, _):
//            guard let operant = operant else {
//                return 10
//            }
//            switch operant {
//            case .plus:
//                return 11
//            case .time:
//                return 12
//            }
//        case .literal(_, _):
//            return 20
//        case .identifier(_):
//            return 30
//        case .symbol(_):
//            return 40
//        case .parenthesis(_):
//            return 50
//        case .separator:
//            return 60
//        case .end:
//            return 70
//        }
//    }
//}
