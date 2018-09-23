//
//  SyntaxAnalysisResources.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/20.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

// TODO: 自動生成スクリプトの作成

/// ~AllowNilAsSame系統は、比較時の右辺左辺どちらかにnilがあるなら
/// trueになることを示しています。

/// 構文解析向けのリソースクラス
class SyntaxAnalysisResources {
    
    // MARK: Nested Types
    
    /// 生成規則
    typealias GenerateRule = (lhs: TokenConstants, rhs: [Token])
    
    /// LR(n)項
    typealias LR0Term = (lhs: TokenConstants, rhs: [Token], point: Int)
    typealias LR1Term = (lhs: TokenConstants, rhs: [Token], point: Int, core: [TokenNode])
    
    // MARL: Computed Properties
    
    /// 文法中に出てくるTokenの列挙
    public static var appearedTokenInSyntax: [Token] {
        get {
            var resultTokens: [Token] = []
            for syntax in definedSyntaxs {
                resultTokens += [syntax.lhs]
                resultTokens += syntax.rhs
            }
            return SyntaxAnalysisResources.makeUnion(array: resultTokens)
        }
    }
    
    // MARK: Constants
    
    /// 定義した生成規則
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
        (lhs: .factor, rhs: [TokenNode.identifier(nil)]),
        
        // return
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return")]),
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return"), TokenNode.identifier(nil)]),
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return"), TokenConstants.expr])
    ]
}

extension SyntaxAnalysisResources {
    
    // MARK: Functions
    
    
    /// Null遷移のある規則であるかどうか求める
    public static func isTokenHaveNullRule(token: Token) -> Bool {
        if token is TokenNode {
            return false
        } else if let token = token as? TokenConstants {
            let definedMatchLhsSyntaxs = definedSyntaxs.filter{ $0.lhs == token }
            for definedMatchLhsSyntax in definedMatchLhsSyntaxs {
                if definedMatchLhsSyntax.rhs.isEmpty {
                    return true
                }
            }
        }
        return false
    }
    
    /// First集合を求める
    public static func calcFirstUnion(token: Token) -> [TokenNode] {
        var resultTokenNodes: [TokenNode] = []
        
        // 終端記号の場合
        if let token = token as? TokenConstants {
            // 生成規則の中で、左辺が合う規則を検索
            let definedMatchLhsSyntaxs = definedSyntaxs.filter{ $0.lhs == token }
            for definedMatchLhsSyntax in definedMatchLhsSyntaxs {
                if let rightToken = definedMatchLhsSyntax.rhs.first as? TokenConstants,
                    rightToken != token {
                    resultTokenNodes += calcFirstUnion(token: rightToken)
                } else if let rightToken = definedMatchLhsSyntax.rhs.first as? TokenNode  {
                    resultTokenNodes += [rightToken]
                }
            }
        }
        // 非終端記号の場合
        else if let token = token as? TokenNode {
            resultTokenNodes += [token]
        }
        return makeUnion(array: resultTokenNodes)
    }
    
    // Tokenの配列のFirst集合を求める
    public static func calcFirstUnionFromTokenArray(tokenArray: [Token]) -> [TokenNode] {
        var resultTokensNodes:[TokenNode] = []
        if tokenArray.count > 0 {
            if isTokenHaveNullRule(token: tokenArray[0]) {
                let tokenArrayPrefix = Array(tokenArray[1..<tokenArray.count])
                if !tokenArrayPrefix.isEmpty {
                    resultTokensNodes += calcFirstUnionFromTokenArray(tokenArray: tokenArrayPrefix)
                }
            } else {
                resultTokensNodes += calcFirstUnion(token: tokenArray[0])
            }
        }
        return resultTokensNodes
    }
    
    /// Follow集合を求める
    public static func calcFollowUnion(token: TokenConstants, isStartCalc: Bool = true) -> [TokenNode] {
        var resultTokenNodes: [TokenNode] = []
        
        // はじめの計算の場合、$を追加
        if isStartCalc {
            resultTokenNodes += [TokenNode.`$`]
        }
        
        let definedSyntaxLhsArray = definedSyntaxs.map{ $0.lhs }
        
        for definedSyntaxLhs in definedSyntaxLhsArray {
            let definedMatchLhsSyntaxs = definedSyntaxs.filter{ $0.lhs == definedSyntaxLhs }
            for definedMatchLhsSyntax in definedMatchLhsSyntaxs {
                for index in 0..<definedMatchLhsSyntax.rhs.count {
                    /// マッチするTokenを探索
                    guard let rhsNodeToConstants = definedMatchLhsSyntax.rhs[index] as? TokenConstants, rhsNodeToConstants == token else {
                        continue
                    }
                    if index + 1 < definedMatchLhsSyntax.rhs.count {
                        if let token =  definedMatchLhsSyntax.rhs[index + 1] as? TokenNode {
                            resultTokenNodes += [token]
                        } else if let token =  definedMatchLhsSyntax.rhs[index + 1] as? TokenConstants {
                            resultTokenNodes += calcFirstUnion(token: token)
                        }
                    }
                    if index == definedMatchLhsSyntax.rhs.count - 1 {
                        resultTokenNodes += calcFollowUnion(token: definedSyntaxLhs, isStartCalc: false)
                    }
                }
            }
        }
        return makeUnion(array: resultTokenNodes)
    }
    
    /// LR1のClosure集合を求める
    public static func calcClosureUnion(lhs: TokenConstants, rhs: [Token], point: Int, core: [TokenNode]) -> [LR1Term]? {
        // 文法に存在しないlhs -> rhsを渡されたらエラー
        guard hasDefinedSyntax(lhs: lhs, rhs: rhs), point <= rhs.count else {
            return nil
        }
        
        var resultLR1TermUnion: [LR1Term] = []
        
        // まず自分自身
        resultLR1TermUnion += [(lhs: lhs, rhs: rhs, point: point, core: core)]
        
        // クロージャのpointが最後のとき、そのまま帰す
        if point == rhs.count {
            return resultLR1TermUnion
        }
        
        // 新しいCoreを求める
        var newCores:[TokenNode] = []
        if point + 1 < rhs.count {
            var tokenNodesForCheckFirstUnion:[Token] = [rhs[point + 1]]
            tokenNodesForCheckFirstUnion += (core as [Token])
            newCores += calcFirstUnionFromTokenArray(tokenArray: tokenNodesForCheckFirstUnion)
        } else {
            newCores += core
        }
       
        // 注目点にあるTokenが非終端記号の場合
        if let pointingToken = rhs[point] as? TokenConstants {
            let definedMatchLhsSyntaxs = definedSyntaxs.filter{ $0.lhs == pointingToken }
            for definedMatchLhsSyntax in definedMatchLhsSyntaxs {
                // 全く同じ文法は二度とも求めない
                if pointingToken == lhs && isSameTokenArrayAllowNilAsSame(rhs, definedMatchLhsSyntax.rhs) && isSameTokenArrayAllowNilAsSame(newCores, core)  {
                    continue
                }
                
                guard let calcedClosureUnion = calcClosureUnion(lhs: definedMatchLhsSyntax.lhs, rhs: definedMatchLhsSyntax.rhs, point: 0, core: newCores) else {
                    return nil
                }
                resultLR1TermUnion += calcedClosureUnion
            }
        }
        
        return calcCombinedClosureUnion(union: resultLR1TermUnion)
    }
    
    /// Closure集合中のかぶりを消す
    public static func calcCombinedClosureUnion(union: [LR1Term]) -> [LR1Term] {
        var resultLR1TermUnion:[LR1Term] = []
        var isCoreAppended = false
        for indexUnion in 0..<union.count {
            for indexResult in 0..<resultLR1TermUnion.count {
                // Core以外が同じな場合、追加
                if resultLR1TermUnion[indexResult].lhs == union[indexUnion].lhs
                    && isSameTokenArrayAllowNilAsSame(resultLR1TermUnion[indexResult].rhs, union[indexUnion].rhs)
                    && resultLR1TermUnion[indexResult].point == union[indexUnion].point {
                    resultLR1TermUnion[indexResult].core += union[indexUnion].core
                    resultLR1TermUnion[indexResult].core = makeUnion(array: resultLR1TermUnion[indexResult].core)
                    isCoreAppended = true
                }
            }
            if !isCoreAppended {
                resultLR1TermUnion.append(union[indexUnion])
            }
            isCoreAppended = false
        }
        return resultLR1TermUnion
    }
    
    /// Goto集合を求める
    public static func calcGotoUnion(lr1TermUnion: [LR1Term], forcusToken: Token) -> [LR1Term]? {
        
        var resultLR1TermUnion: [LR1Term] = []
        
        for pointedSyntax in lr1TermUnion {
            if pointedSyntax.point < pointedSyntax.rhs.count
                && pointedSyntax.rhs[pointedSyntax.point].isEqualAllowNilAsSame(to: forcusToken) {
                guard let calcedClosureUnion = calcClosureUnion(lhs: pointedSyntax.lhs,
                                                         rhs: pointedSyntax.rhs,
                                                         point: pointedSyntax.point + 1,
                                                         core: pointedSyntax.core) else {
                    return nil
                }
                resultLR1TermUnion += calcedClosureUnion
            }
        }
        
        return resultLR1TermUnion
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

    /// 同じToken列を削除する(LR0)
    private static func makeUnion(array: [LR0Term]) -> [LR0Term] {
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
    
    /// 同じToken列を削除する(LR1)
    private static func makeUnion(union: [LR1Term]) -> [LR1Term] {
        var result:[LR1Term] = []
        for element in union {
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
    
    /// 同じToken列を削除する(Token)
    private static func makeUnion(array: [Token]) -> [Token] {
        var result:[Token] = []
        for element in array {
            if !result.contains(where: { element.isEqualAllowNilAsSame(to: $0) }) {
                result.append(element)
            }
        }
        return result
    }
    
    /// 同じToken列を削除する(TokenNode)
    private static func makeUnion(array: [TokenNode]) -> [TokenNode] {
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
    
    /// nilを同じと捉える比較
    private func compareAllowNilAsSame<E: Equatable>(lhs: E?, rhs: E?) -> Bool {
        if lhs == nil || rhs == nil {
            return true
        }
        return lhs == rhs
    }
    
    public func isEqualAllowNilAsSame(to rhs: TokenNode) -> Bool {
        
        switch (self, rhs) {
        case (.keyword(let ll, let lr), .keyword(let rl, let rr)):
            return compareAllowNilAsSame(lhs: ll, rhs: rl)
                && compareAllowNilAsSame(lhs: lr, rhs: rr)
        case (.operant(let ll, let lr), .operant(let rl, let rr)):
            return compareAllowNilAsSame(lhs: ll, rhs: rl)
                && compareAllowNilAsSame(lhs: lr, rhs: rr)
        case (.literal(let ll, let lr), .literal(let rl, let rr)):
            return compareAllowNilAsSame(lhs: ll, rhs: rl)
                && compareAllowNilAsSame(lhs: lr, rhs: rr)
        case (.identifier(let l), .identifier(let r)):
            return compareAllowNilAsSame(lhs: l, rhs: r)
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
    
    // MARK: Combine function
    
    /// 同じ長さの配列２つをまとめる
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

