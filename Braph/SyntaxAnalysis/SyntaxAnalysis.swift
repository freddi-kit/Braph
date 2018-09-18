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
        if let token = token as? TokenConstants, let rightTokens = definedSyntaxs[token] {
            for rigthToken in rightTokens {
                if let rightTokenFirst = rigthToken.nodes.first {
                    if ((rightTokenFirst as? TokenConstants) != nil) && rigthToken.nodes.count >= 2 {
                        resultTokens += calcFirstUnion(token: rigthToken.nodes[1])
                    } else {
                        resultTokens += calcFirstUnion(token: rightTokenFirst)
                    }
                }
            }
        }
        else if let token = token as? TokenNode {
            resultTokens += [token]
        }
        return Array(Set(resultTokens))
    }
    
    /// Follow集合を求める
    public static func calcFollowUnion(token: TokenConstants) -> Array<TokenNode> {
        var resultTokens: Array<TokenNode> = []
        for definedSyntaxKey in definedSyntaxs.keys {
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
                            resultTokens += calcFollowUnion(token: definedSyntaxKey)
                        }
                    }
                }
            }
        }
        return Array(Set(resultTokens))
    }
}

// First、Follow向けの拡張
extension TokenNode: Equatable {
    static func == (lhs: TokenNode, rhs: TokenNode) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// First、Follow向けの拡張
extension TokenNode: Hashable {
    var hashValue: Int {
        switch self {
        case let .keyword(keyWord, _):
            switch keyWord {
            case .define:
                return 0
            case .return:
                return 1
            case .type:
                return 2
            }
        case let .operant(operant, _):
            guard let operant = operant else {
                return 10
            }
            switch operant {
            case .plus:
                return 11
            case .time:
                return 12
            }
        case .literal(_, _):
            return 20
        case .identifier(_):
            return 30
        case .symbol(_):
            return 40
        case .parenthesis(_):
            return 50
        case .separator:
            return 60
        case .end:
            return 70
        }
    }
}
