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
    
    // MARK: 型
    typealias GenerateRule = (lhs: TokenConstants, rhs: [Token])
    typealias LR0Term = (lhs: TokenConstants, rhs: [Token], point: Int)
    typealias LR1Term = (lhs: TokenConstants, rhs: [Token], point: Int, core: [TokenNode])
    
    // MARL: Computed
    
    /// 文法中に出てくるTokenの列挙
    public static var appearedTokenInSyntax: [Token] {
        get {
            var result: [Token] = []
            for syntax in definedSyntaxs {
                result += [syntax.lhs]
                result += syntax.rhs
            }
            return SyntaxAnalysisResources.reduceSameElementFromTokenUnion(array: result)
        }
    }
    
    // MARK: Constants
    
    public static let definedSyntaxs: [GenerateRule] = [
        // (for extended syntax)
        (lhs: .start, rhs: [TokenConstants.statement]),

        // statement
        (lhs: .statement, rhs: [TokenConstants.declaration]),
        (lhs: .statement, rhs: [TokenConstants.expr]),
        (lhs: .statement, rhs: [TokenConstants.return]),
        (lhs: .statement, rhs: [TokenConstants.assign]),

        // declaration
        (lhs: .declaration, rhs: [TokenNode.keyword(.declaration, nil), TokenNode.identifier(nil), TokenConstants.initializer]),
        (lhs: .initializer, rhs:[TokenNode.symbol("="), TokenConstants.expr]),
        
        // assign
        (lhs: .assign, rhs: [TokenNode.identifier(nil), TokenConstants.initializer]),
        
        // expression
        (lhs: .expr, rhs: [TokenConstants.expr, TokenNode.operant(.plus, nil), TokenConstants.term]),
        (lhs: .expr, rhs: [TokenConstants.term]),
        (lhs: .term, rhs: [TokenConstants.term, TokenNode.operant(.time, nil), TokenConstants.factor]),
        (lhs: .term, rhs: [TokenConstants.factor]),
        /// うまくいかないっぽい、これ
        (lhs: .factor, rhs: [TokenNode.parenthesis("("), TokenConstants.expr, TokenNode.parenthesis(")")]),
        (lhs: .factor, rhs: [TokenNode.literal(nil, nil)]),
        
        // return
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return")]),
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return"), TokenNode.identifier(nil)]),
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return"), TokenConstants.expr])
    ]
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
    public static func calcClosureUnion(lhs: TokenConstants, rhs: [Token], point: Int) -> [LR0Term]? {
        guard hasDefinedSyntax(lhs: lhs, rhs: rhs), point <= rhs.count else {
            return nil
        }
        var resultUnion: [LR0Term] = []
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
    
    /// Closure集合を求める
    public static func calcClosureUnion(lhs: TokenConstants, rhs: [Token], point: Int, core: [TokenNode]) -> [LR1Term]? {
        guard hasDefinedSyntax(lhs: lhs, rhs: rhs), point <= rhs.count else {
            return nil
        }
        var resultUnion: [LR1Term] = []
        resultUnion += [(lhs: lhs, rhs: rhs, point: point, core: core)]
        
        if point == rhs.count {
            return resultUnion
        }
        
        var newCores:[TokenNode] = []
        if point + 1 < rhs.count {
            newCores += calcFirstUnion(token: rhs[point + 1])
        } else {
            newCores += core
        }
       
        
        let pointingToken = rhs[point]
        if let pointingToken = pointingToken as? TokenConstants {
            let definedSyntax = definedSyntaxs.filter{ $0.lhs == pointingToken }
            for syntax in definedSyntax {
                if pointingToken == lhs && isSameTokenArrayAllowNilAsSame(rhs, syntax.rhs) && isSameTokenArrayAllowNilAsSame(newCores, core)  {
                    continue
                }
                
                guard let calcedClosureUnion = calcClosureUnion(lhs: syntax.lhs, rhs: syntax.rhs, point: 0, core: newCores) else {
                    return nil
                }
                resultUnion += calcedClosureUnion
            }
        }
        
        return calcCombinedClosureUnion(in: resultUnion)
    }
    
    public static func calcCombinedClosureUnion(in union: [LR1Term]) -> [LR1Term] {
        var result:[LR1Term] = []
        var isCoreAppended = false
        for indexUnion in 0..<union.count {
            for indexResult in 0..<result.count {
                if result[indexResult].lhs == union[indexUnion].lhs
                    && isSameTokenArrayAllowNilAsSame(result[indexResult].rhs, union[indexUnion].rhs)
                    && result[indexResult].point == union[indexUnion].point {
                    result[indexResult].core += union[indexUnion].core
                    result[indexResult].core = reduceSameElementFromTokenNodeUnion(array: result[indexResult].core)
                    isCoreAppended = true
                }
            }
            if !isCoreAppended {
                result.append(union[indexUnion])
            }
            isCoreAppended = false
        }
        return reduceSameElementFromTokenSyntaxUnion(array: result)
    }
    
    /// Goto集合を求める
    public static func calcGotoUnion(i: [LR1Term], forcusToken: Token) -> [LR1Term]? {
        
        var resultUnion: [LR1Term] = []
        
        for pointedSyntax in i {
            if pointedSyntax.point < pointedSyntax.rhs.count
                && pointedSyntax.rhs[pointedSyntax.point].isEqualAllowNilAsSame(to: forcusToken) {
                guard let calcedUnion = calcClosureUnion(lhs: pointedSyntax.lhs,
                                                         rhs: pointedSyntax.rhs,
                                                         point: pointedSyntax.point + 1,
                                                         core: pointedSyntax.core) else {
                    return nil
                }
                resultUnion += calcedUnion
            }
        }
        
        return resultUnion
    }
    
    /// 同じクロージャ集合？LR0
    public static func isSameClosureUnion(i1: [LR0Term], i2: [LR0Term]) -> Bool {
        return i1.combine(i2)?.reduce(true, { (result, arg) -> Bool in
            return result && arg.0.lhs.isEqualAllowNilAsSame(to: arg.1.lhs)
                && isSameTokenArrayAllowNilAsSame(arg.0.rhs, arg.1.rhs)
                && arg.0.point == arg.1.point
        }) ?? false
    }
    
    /// 同じクロージャ集合？LR1
    public static func isSameClosureUnion(i1: [LR1Term], i2: [LR1Term]) -> Bool {
        return i1.combine(i2)?.reduce(true, { (result, arg) -> Bool in
            return result && arg.0.lhs ==  arg.1.lhs
                && isSameTokenArrayAllowNilAsSame(arg.0.rhs, arg.1.rhs)
                && arg.0.point == arg.1.point
                && isSameTokenArrayAllowNilAsSame(arg.0.core, arg.1.core)
        }) ?? false
    }

    /// Set使えないための対策１
    private static func reduceSameElementFromTokenSyntaxUnion(array: [LR0Term]) -> [LR0Term] {
        var result:[LR0Term] = []
        for element in array {
            if !result.contains(where: {
                $0.lhs == element.lhs
                    && $0.point == element.point
                    && isSameTokenArrayAllowNilAsSame($0.rhs, element.rhs) }) {
                result.append(element)
            }
        }
        return result
    }
    
    private static func reduceSameElementFromTokenSyntaxUnion(array: [LR1Term]) -> [LR1Term] {
        var result:[LR1Term] = []
        for element in array {
            if !result.contains(where: {
                $0.lhs ==  element.lhs
                    && isSameTokenArrayAllowNilAsSame($0.rhs, element.rhs)
                    && $0.point == element.point
                    && isSameTokenArrayAllowNilAsSame($0.core, element.core) }) {
                result.append(element)
            }
        }
        return result
    }
    
    /// Set使えないための対策２
    private static func reduceSameElementFromTokenUnion(array: [Token]) -> [Token] {
        var result:[Token] = []
        for element in array {
            if !result.contains(where: { element.isEqualAllowNilAsSame(to: $0) }) {
                result.append(element)
            }
        }
        return result
    }
    
    private static func reduceSameElementFromTokenNodeUnion(array: [TokenNode]) -> [TokenNode] {
        var result:[TokenNode] = []
        for element in array {
            if !result.contains(where: { element.isEqualAllowNilAsSame(to: $0) }) {
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
                return tokens.0.isEqualAllowNilAsSame(to: tokens.1)
            }) {
                if hasSyntax == true {
                    return true
                }
            }
        }
        return false
    }
    
    /// 同じノード配列かどうか？
    public static func isSameTokenArrayAllowNilAsSame(_ lhs: [Token], _ rhs: [Token]) -> Bool {
        guard let hasSameNode = lhs.combine(rhs)?.reduce(true, { (beforeResult, tokens) -> Bool in
            return tokens.0.isEqualAllowNilAsSame(to: tokens.1)
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
    
    public func isEqualAllowNilAsSame(to rhs: TokenNode) -> Bool {
        
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

