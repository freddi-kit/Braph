//
//  SyntaxAnalysisResources.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/20.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

typealias GenerateRule = (lhs: TokenConstants, rhs: [Token])

// TODO: 自動生成スクリプトの作成

/// ~AllowNilAsSame系統は、比較時の右辺左辺どちらかにnilがあるなら
/// trueになることを示しています。

/// 構文解析向けのリソースクラス
class SyntaxAnalysisResources {
    
    // MARK: Nested Types

    /// LR(n)項
    typealias LR0Term = (lhs: TokenConstants, rhs: [Token], point: Int)
    typealias LR1Term = (lhs: TokenConstants, rhs: [Token], point: Int, core: [TokenNode])
    
    // MARL: Stored Properties
    
    /// 定義した生成規則
    public let definedSyntaxs: [GenerateRule]
    
    // MARK: Initalizers
    init(definedSyntaxs: [GenerateRule]) {
        self.definedSyntaxs = definedSyntaxs
    }
    
    // MARL: Computed Properties
    
    /// 文法中に出てくるTokenの列挙
    public var appearedTokenInSyntax: [Token] {
        get {
            var resultTokens: [Token] = []
            for syntax in definedSyntaxs {
                resultTokens += [syntax.lhs]
                resultTokens += syntax.rhs
            }
            return makeUnion(array: resultTokens)
        }
    }
}

extension SyntaxAnalysisResources {
    
    // MARK: Functions
    
    
    /// Null遷移のあるTokenであるかどうか求める
    public func isTokenHaveNullRule(token: Token, startToken: Token? = nil) -> Bool {
        
        // もし終端記号のときは強制的にfalse、非終端の場合は遷移先を見る
        if token is TokenNode {
            return false
        } else if let token = token as? TokenConstants {
            var result = false
            // 遷移先をすべて洗い出し
            let definedMatchLhsSyntaxs = definedSyntaxs.filter{ $0.lhs == token }
            for definedMatchLhsSyntax in definedMatchLhsSyntaxs {
                if definedMatchLhsSyntax.rhs.isEmpty {
                    return true
                }
                if definedMatchLhsSyntax.rhs.count == 1
                    && ((startToken == nil)
                        || (!definedMatchLhsSyntax.rhs[0].isEqualAllowNilAsSame(to: startToken!))
                    ) {
                    result = result && isTokenHaveNullRule(token: definedMatchLhsSyntax.rhs[0], startToken: startToken)
                }
            }
            return result
        }
        return false
    }
    
    /// First集合を求める
    public func calcFirstUnion(token: Token) -> [TokenNode] {
        var resultTokenNodes: [TokenNode] = []
        
        // 終端記号の場合
        if let token = token as? TokenConstants {
            // 生成規則の中で、左辺が合う規則を検索
            let definedMatchLhsSyntaxs = definedSyntaxs.filter{ $0.lhs == token }
            for definedMatchLhsSyntax in definedMatchLhsSyntaxs {
                if let rightTokenFirst = definedMatchLhsSyntax.rhs.first as? TokenConstants {
                    // 無限ループ防止・rhsの先頭と調べたいTokenが同じの場合
                    if rightTokenFirst != token {
                        resultTokenNodes += calcFirstUnionFromTokenArray(tokenArray: definedMatchLhsSyntax.rhs)
                    }
                    // もし、先頭がNull遷移を行う可能性があるときも考慮
                    else if isTokenHaveNullRule(token: rightTokenFirst) &&
                        !definedMatchLhsSyntax.rhs[1..<definedMatchLhsSyntax.rhs.count].isEmpty {
                        // rhsの先頭以外でチェック
                        resultTokenNodes += calcFirstUnionFromTokenArray(tokenArray: Array(definedMatchLhsSyntax.rhs[1..<definedMatchLhsSyntax.rhs.count]))
                    }
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
    public func calcFirstUnionFromTokenArray(tokenArray: [Token]) -> [TokenNode] {
        var resultTokensNodes:[TokenNode] = []
        if tokenArray.count > 0 {
            resultTokensNodes += calcFirstUnion(token: tokenArray[0])
            if isTokenHaveNullRule(token: tokenArray[0]) {
                let tokenArrayPrefix = Array(tokenArray[1..<tokenArray.count])
                if !tokenArrayPrefix.isEmpty {
                    resultTokensNodes += calcFirstUnionFromTokenArray(tokenArray: tokenArrayPrefix)
                }
            }
        }
        return resultTokensNodes
    }
    
    /// Follow集合を求める
    public func calcFollowUnion(token: TokenConstants, isStartCalc: Bool = true) -> [TokenNode] {
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
    public func calcClosureUnion(lhs: TokenConstants, rhs: [Token], point: Int, core: [TokenNode]) -> [LR1Term]? {
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
        var newCores: [TokenNode] = []
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
                // 全く同じ文法は二度と求めない
                if pointingToken == lhs
                    && isSameTokenRuleAllowNilAsSame(rhs, definedMatchLhsSyntax.rhs)
                    && isSameTokenArrayAllowNilAsSame(newCores, core)  {
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
    public func calcCombinedClosureUnion(union: [LR1Term]) -> [LR1Term] {
        
        var resultLR1TermUnion:[LR1Term] = []
        
        var isCoreAppended = false
        for indexUnion in 0..<union.count {
            for indexResult in 0..<resultLR1TermUnion.count {
                // Core以外が同じな場合、追加
                if resultLR1TermUnion[indexResult].lhs == union[indexUnion].lhs
                    && isSameTokenRuleAllowNilAsSame(resultLR1TermUnion[indexResult].rhs, union[indexUnion].rhs)
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
    public func calcGotoUnion(lr1TermUnion: [LR1Term], forcusToken: Token) -> [LR1Term]? {
        
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
    public func isSameClosureUnion(_ lhs: [LR0Term], _ rhs: [LR0Term]) -> Bool {
        
        if rhs.count != lhs.count {
            return false
        }
        
        var lhsIndexStack: [Int] = []
        for rhsTerm in rhs {
            for lhsIndex in 0..<lhs.count {
                if lhsIndexStack.contains(lhsIndex) {
                    continue
                }
                if lhs[lhsIndex].lhs == rhsTerm.lhs
                    && isSameTokenRuleAllowNilAsSame(lhs[lhsIndex].rhs, rhsTerm.rhs)
                    && lhs[lhsIndex].point == rhsTerm.point {
                    lhsIndexStack.append(lhsIndex)
                }
            }
        }
        return lhsIndexStack.count == lhs.count
    }
    
    /// 同じクロージャ集合？LR1
    public func isSameClosureUnion(_ lhs: [LR1Term], _ rhs: [LR1Term]) -> Bool {
        
        if rhs.count != lhs.count {
            return false
        }
        
        var lhsIndexStack: [Int] = []
        for rhsTerm in rhs {
            for lhsIndex in 0..<lhs.count {
                if lhsIndexStack.contains(lhsIndex) {
                    continue
                }
                if lhs[lhsIndex].lhs == rhsTerm.lhs
                    && isSameTokenRuleAllowNilAsSame(lhs[lhsIndex].rhs, rhsTerm.rhs)
                    && lhs[lhsIndex].point == rhsTerm.point
                    && isSameTokenArrayAllowNilAsSame(lhs[lhsIndex].core, rhsTerm.core){
                    lhsIndexStack.append(lhsIndex)
                }
            }
        }
        return lhsIndexStack.count == lhs.count
    }

    /// 同じToken列を削除する(LR0)
    private func makeUnion(array: [LR0Term]) -> [LR0Term] {
        var result:[LR0Term] = []
        for element in array {
            if !result.contains(where: {
                $0.lhs == element.lhs
                    && $0.point == element.point
                    && isSameTokenRuleAllowNilAsSame($0.rhs, element.rhs) }) {
                result.append(element)
            }
        }
        return result
    }
    
    /// 同じToken列を削除する(LR1)
    private func makeUnion(union: [LR1Term]) -> [LR1Term] {
        var result:[LR1Term] = []
        for element in union {
            if !result.contains(where: {
                $0.lhs ==  element.lhs
                    && isSameTokenRuleAllowNilAsSame($0.rhs, element.rhs)
                    && $0.point == element.point
                    && isSameTokenArrayAllowNilAsSame($0.core, element.core) }) {
                result.append(element)
            }
        }
        return result
    }
    
    /// 同じToken列を削除する(Token)
    private func makeUnion(array: [Token]) -> [Token] {
        var result:[Token] = []
        for element in array {
            if !result.contains(where: { element.isEqualAllowNilAsSame(to: $0) }) {
                result.append(element)
            }
        }
        return result
    }
    
    /// 同じToken列を削除する(TokenNode)
    private func makeUnion(array: [TokenNode]) -> [TokenNode] {
        var result:[TokenNode] = []
        for element in array {
            if !result.contains(where: { element.isEqualTokenAllowNilAsSame(to: $0) }) {
                result.append(element)
            }
        }
        return result
    }
    
    /// Closureで不正な文法渡すの防止
    private func hasDefinedSyntax(lhs: TokenConstants, rhs: [Token]) -> Bool {
        let definedRhs = definedSyntaxs.filter{ $0.lhs == lhs }
        
        for syntax in definedRhs {
            if let hasSyntax = rhs.combineIfSameLength(syntax.rhs)?.reduce(true, { (beforeResult, tokens) -> Bool in
                return tokens.0.isEqualAllowNilAsSame(to: tokens.1)
            }) {
                if hasSyntax {
                    return true
                }
            }
        }
        return false
    }
    
    /// 同じノード配列（順番も考慮）か？
    public func isSameTokenRuleAllowNilAsSame(_ lhs: [Token], _ rhs: [Token]) -> Bool {
        return lhs.combineIfSameLength(rhs)?.reduce(true, { (beforeResult, tokens) -> Bool in
                return beforeResult && tokens.0.isEqualAllowNilAsSame(to: tokens.1)
        }) ?? false
    }
    
    /// 同じノード配列かどうか？
    public func isSameTokenArrayAllowNilAsSame(_ lhs: [Token], _ rhs: [Token]) -> Bool {
        if lhs.count != rhs.count {
            return false
        }

        var lhsIndexStack: [Int] = []
        for rhsToken in rhs {
            for lhsIndex in 0..<lhs.count {
                if lhsIndexStack.contains(lhsIndex) {
                    continue
                }
                if lhs[lhsIndex].isEqualAllowNilAsSame(to: rhsToken)  {
                    lhsIndexStack.append(lhsIndex)
                }
            }
        }
        return lhsIndexStack.count == lhs.count
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
    
    public func isEqualTokenAllowNilAsSame(to rhs: TokenNode) -> Bool {
        
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
        case (.end, .end), (.`$`, .`$`):
            return true
        default:
            return false
        }
    }
}

extension Collection {
    
    // MARK: Combine function
    
    /// 同じ長さの配列２つをまとめる
    func combineIfSameLength<C: Collection>(_ collection: C) -> [(Element, Element)]? where C.Element == Element {
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

