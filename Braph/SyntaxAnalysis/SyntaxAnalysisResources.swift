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
    
    public static let definedSyntaxs: [(lhs: TokenConstants, rhs: [Token])] = [
        // (for extended syntax)
        (lhs: .start, rhs: [TokenConstants.expr]),
        
        // statement
        (lhs: .statement, rhs: [TokenConstants.declaration]),
        (lhs: .statement, rhs: [TokenConstants.expr]),
        (lhs: .statement, rhs: [TokenConstants.return]),
        
        // declaration
        (lhs: .declaration, rhs: [TokenNode.keyword(.declaration, nil), TokenNode.identifier(nil), TokenConstants.initializer]),
        (lhs: .initializer, rhs:[TokenNode.symbol("="), TokenConstants.expr]),
        
        // expression
        (lhs: .expr, rhs: [TokenConstants.expr, TokenNode.operant(.plus, nil), TokenConstants.term]),
        (lhs: .expr, rhs: [TokenConstants.term]),
        (lhs: .term, rhs: [TokenConstants.term, TokenNode.operant(.time, nil), TokenConstants.factor]),
        (lhs: .term, rhs: [TokenConstants.factor]),
        (lhs: .factor, rhs: [TokenNode.parenthesis("("), TokenConstants.expr, TokenNode.parenthesis(")")]),
        (lhs: .factor, rhs: [TokenNode.literal(nil, nil)]),
        
        // return
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return")]),
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return"), TokenNode.identifier(nil)]),
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return"), TokenConstants.expr])
    ]
    
    // 文法の宣言
//    public static let definedSyntaxs: [TokenConstants: [SyntaxTree]] = [
//        .define : [
//            .init([TokenNode.keyword(.define, nil), TokenNode.identifier(nil), TokenNode.symbol("="),  TokenConstants.expr])
//        ],
//        .expr : [
//            .init([TokenConstants.expr, TokenNode.operant(.plus, nil), TokenConstants.term]),
//            .init([TokenConstants.term])
//        ],
//        .term : [
//            .init([TokenConstants.term, TokenNode.operant(.time, nil), TokenConstants.factor]),
//            .init([TokenConstants.factor])
//        ],
//        .factor :  [
//            .init([TokenNode.literal(nil, nil)]),
//            .init([TokenNode.parenthesis("("), TokenConstants.expr, TokenNode.parenthesis(")")])
//        ]
//    ]
}

extension SyntaxAnalysisResources {
    
    // MARK: Functions

    /// First集合を求める
    public static func calcFirstUnion(token: Token) -> [TokenNode] {
        var resultTokens: Array<TokenNode> = []
        if let token = token as? TokenConstants {
            let definedMatchLhsSyntaxs = definedSyntaxs.filter{ $0.lhs == token }
            for definedMatchLhsSyntax in definedMatchLhsSyntaxs {
                if let rightToken = definedMatchLhsSyntax.rhs.first as? TokenConstants,
                    rightToken != token {
                    resultTokens += calcFirstUnion(token: rightToken)
                } else if let rightToken = definedMatchLhsSyntax.rhs.first as? TokenNode  {
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
        
        let definedSyntaxLhses = definedSyntaxs.map{ $0.lhs }
        
        for definedSyntaxLhs in definedSyntaxLhses {
            let definedMatchLhsSyntaxs = definedSyntaxs.filter{ $0.lhs == definedSyntaxLhs }
            for definedMatchLhsSyntax in definedMatchLhsSyntaxs {
                for index in 0..<definedMatchLhsSyntax.rhs.count {
                    if let nodeToConstants = definedMatchLhsSyntax.rhs[index] as? TokenConstants, nodeToConstants == token {
                        if index + 1 < definedMatchLhsSyntax.rhs.count {
                            if let token =  definedMatchLhsSyntax.rhs[index + 1] as? TokenNode {
                                resultTokens += [token]
                            } else if let token =  definedMatchLhsSyntax.rhs[index + 1] as? TokenConstants {
                                resultTokens += calcFirstUnion(token: token)
                            }
                        }
                        if index ==  definedMatchLhsSyntax.rhs.count - 1 {
                            resultTokens += calcFollowUnion(token: definedSyntaxLhs)
                        }
                    }
                }
            }
        }
        return reduceSameElementFromTokenNodeUnion(array: resultTokens)
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
        if let pointingToken = pointingToken as? TokenConstants {
            let definedSyntax = definedSyntaxs.filter{ $0.lhs == pointingToken }
            for syntax in definedSyntax {
                if pointingToken == lhs {
                    if isSameTokenArrayAllowNilAsSame(rhs, syntax.rhs) {
                        continue
                    }
                }
                guard let calcedClosureUnion = calcClosureUnion(lhs: pointingToken, rhs: syntax.rhs, point: 0) else {
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
    
    /// 同じクロージャ集合？
    public static func isSameClosureUnion(i1: [(lhs: TokenConstants, rhs: [Token], point: Int)], i2: [(lhs: TokenConstants, rhs: [Token], point: Int)]) -> Bool {
        return i1.combine(i2)?.reduce(true, { (result, arg) -> Bool in
            return result && arg.0.lhs.isEqualAndAllowNilAsSame(to: arg.1.lhs)
                && arg.0.lhs.isEqualAndAllowNilAsSame(to: arg.1.lhs)
                && isSameTokenArrayAllowNilAsSame(arg.0.rhs, arg.1.rhs)
        }) ?? false
    }

    /// Set使えないための対策１
    private static func reduceSameElementFromTokenSyntaxUnion(array: [(lhs: TokenConstants, rhs: [Token], point: Int)]) -> [(lhs: TokenConstants, rhs: [Token], point: Int)] {
        var result:[(lhs: TokenConstants, rhs: [Token], point: Int)] = []
        for element in array {
            if !result.contains(where: {
                $0.point == element.point &&
                $0.lhs == element.lhs &&
                isSameTokenArrayAllowNilAsSame($0.rhs, element.rhs) }) {
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
        let definedRhs = definedSyntaxs.filter{ $0.lhs == lhs }
        
        for syntax in definedRhs {
            if let hasSyntax = rhs.combine(syntax.rhs)?.reduce(true, { (beforeResult, tokens) -> Bool in
                return tokens.0.isEqualAndAllowNilAsSame(to: tokens.1)
            }) {
                if hasSyntax == true {
                    return true
                }
            }
        }
        return false
    }
    
    /// 同じノード配列かどうか？
    private static func isSameTokenArrayAllowNilAsSame(_ lhs: [Token], _ rhs: [Token]) -> Bool {
        guard let hasSameNode = lhs.combine(rhs)?.reduce(true, { (beforeResult, tokens) -> Bool in
            return tokens.0.isEqualAndAllowNilAsSame(to: tokens.1)
        }) else {
            return false
        }
        return hasSameNode
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

extension Collection {
    
    // こんびーん！
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

