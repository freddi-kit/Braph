//
//  SyntaxAnalysisResources.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/20.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

// TODO: 自動生成スクリプトの作成

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
    public static func calcFollowUnion(token: TokenConstants) -> [TokenNode] {
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
    
    private static func isSameTokenNodeArrayAllowNilAsSame(_ lhs: [Token], _ rhs: [Token]) -> Bool {
        guard let hasSameNode = lhs.combine(rhs)?.reduce(true, { (beforeResult, tokens) -> Bool in
            return tokens.0.isEqualAndAllowNilAsSame(to: tokens.1)
        }) else {
            return false
        }
        return hasSameNode
    }
    
    
    /// Closure集合を求める
    public static func calcClosureUnion(lhs: TokenConstants, rhs: [Token], point: Int) -> [(lhs: TokenConstants, rhs: [Token], point: Int)]? {
        guard hasDefinedSyntax(lhs: lhs, rhs: rhs), point <= rhs.count else {
            return nil
        }
        var resultUnion: [(lhs: TokenConstants, rhs: [Token], point: Int)] = []
        resultUnion += [(lhs: lhs, rhs: rhs, point: point)]
        if point == rhs.count {
            return resultUnion
        }
        let pointingToken = rhs[point]
        if let pointingToken = pointingToken as? TokenConstants, let definedSyntax = definedSyntaxs[pointingToken] {
            for syntax in definedSyntax {
                if pointingToken == lhs {
                    if isSameTokenNodeArrayAllowNilAsSame(rhs, syntax.nodes) {
                        continue
                    }
                }
                guard let calcedClosureUnion = calcClosureUnion(lhs: pointingToken, rhs: syntax.nodes, point: 0) else {
                    return nil
                }
                resultUnion += calcedClosureUnion
            }
        }
        
        return reduceSameElementFromTokenSyntaxUnion(array: resultUnion)
    }
    
    /// Goto集合を求める
    public static func calcGotoUnion(i: [(lhs: TokenConstants, rhs: [Token], point: Int)], forcusToken: Token) -> [(lhs: TokenConstants, rhs: [Token], point: Int)]? {
        
        var resultUnion: [(lhs: TokenConstants, rhs: [Token], point: Int)] = []
        
        for pointedSyntax in i {
            if pointedSyntax.point < pointedSyntax.rhs.count && pointedSyntax.rhs[pointedSyntax.point].isEqualAndAllowNilAsSame(to: forcusToken) {
                guard let calcedUnion = calcClosureUnion(lhs: pointedSyntax.lhs, rhs: pointedSyntax.rhs, point: pointedSyntax.point + 1) else {
                    return nil
                }
                resultUnion += calcedUnion
            }
        }
        
        return resultUnion
    }

    /// Set使えないための対策１
    private static func reduceSameElementFromTokenSyntaxUnion(array: [(lhs: TokenConstants, rhs: [Token], point: Int)]) -> [(lhs: TokenConstants, rhs: [Token], point: Int)] {
        var result:[(lhs: TokenConstants, rhs: [Token], point: Int)] = []
        for element in array {
            if !result.contains(where: {
                $0.point == element.point &&
                $0.lhs == element.lhs &&
                isSameTokenNodeArrayAllowNilAsSame($0.rhs, element.rhs) }) {
                result.append(element)
            }
        }
        return result
    }
    
    /// Set使えないための対策２
    private static func reduceSameElementFromTokenNodeUnion(array: [TokenNode]) -> [TokenNode] {
        var result:[TokenNode] = []
        for element in array {
            if !result.contains(where: { element.isEqualAllowNilAsSame($0) }) {
                result.append(element)
            }
        }
        return result
    }
    
    /// Closureで不正な文法渡すの防止
    private static func hasDefinedSyntax(lhs: TokenConstants, rhs: [Token]) -> Bool {
        guard let definedRhs = definedSyntaxs[lhs] else {
            return false
        }
        
        for syntax in definedRhs {
            if let hasSyntax = rhs.combine(syntax.nodes)?.reduce(true, { (beforeResult, tokens) -> Bool in
                return tokens.0.isEqualAndAllowNilAsSame(to: tokens.1)
            }) {
                if hasSyntax == true {
                    return true
                }
            }
        }
        return false
    }
}


extension TokenNode {
    // MARK: First、Follow向けの拡張
    
    private func compareAllowNilAsSame<E1: Equatable, E2: Equatable>(ll: E1?, lr: E2?, rl: E1?, rr: E2?) -> Bool {
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
    
    public func isEqualAllowNilAsSame(_ rhs: TokenNode) -> Bool {
        
        switch (self, rhs) {
        case (.keyword(let ll, let lr), .keyword(let rl, let rr)):
            return compareAllowNilAsSame(ll: ll, lr: lr, rl: rl, rr: rr)
        case (.operant(let ll, let lr), .operant(let rl, let rr)):
            return compareAllowNilAsSame(ll: ll, lr: lr, rl: rl, rr: rr)
        case (.literal(let ll, let lr), .literal(let rl, let rr)):
            return compareAllowNilAsSame(ll: ll, lr: lr, rl: rl, rr: rr)
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

extension Array where Element == Token {
    
}

extension Collection {
    func combine<C: Collection>(_ collection: C) -> [(Element, Element)]? where C.Element == Element {
        guard collection.count == self.count, let castedSelf = self as? [Element], let collection = collection as? [Element] else {
            return nil
        }
        var result: [(Element, Element)] = []
        for index in 0..<collection.count {
            result.append((castedSelf[index], collection[index]))
        }
        
        return result
    }
}

