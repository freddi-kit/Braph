//
//  SyntaxAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/09.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

class SyntaxAnalysis {
    
    // MARL: Properties
    
    private var definedSyntaxs: [GenerateRule] = [
        
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
        (lhs: .factor, rhs: [TokenNode.parenthesis("("), TokenConstants.expr, TokenNode.parenthesis(")")]),
        (lhs: .factor, rhs: [TokenNode.literal(nil, nil)]),
        (lhs: .factor, rhs: [TokenNode.identifier(nil)]),
        
        // return
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return")]),
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return"), TokenNode.identifier(nil)]),
        (lhs: .return, rhs: [TokenNode.keyword(.return, "return"), TokenConstants.expr]),
    ]
    
    // 状態遷移表
    private var actionSheet: [(input: Token, status: Int, isShift: Bool, isAccept: Bool, goTo: Int)] = []
    
    private let syntaxAnalysisResources: SyntaxAnalysisResources
    
    // MARK: Initializer
    
    init() {
        syntaxAnalysisResources = .init(definedSyntaxs: definedSyntaxs)
        makeActionSheet()
        if demoModeAtSyn {
            print("action count: ", actionSheet.count)
            for action in actionSheet {
                print(action)
            }
        }
    }
    
    // MARK: Public functions
    
    /// 構文解析
    public func analysis(input inputTokens: [TokenNode]) -> SyntaxTree? {
        var nowStatusStack: [Int] = [0]
        var inputTokenIndex = 0
        var resultSyntaxs: [GenerateRule] = []
        
        while inputTokenIndex < inputTokens.count {
            
            let inputToken = inputTokens[inputTokenIndex]
            
            if demoModeAtSyn {
                print("input is :", inputTokens[inputTokenIndex])
            }
            
            guard let nowStatus = nowStatusStack.last else {
                return nil
            }
            
            if demoModeAtSyn {
                print("status is :", nowStatus)
            }
            
            let getFromActionSheet = actionSheet.filter{ $0.input.isEqualAllowNilAsSame(to: inputToken) && $0.status == nowStatus }
            
            guard let action = getFromActionSheet.first else {
                if demoModeAtSyn {
                    print("No action")
                }
                return nil
            }
            
            if demoModeAtSyn {
                print("action is ",action)
            }
            
            if action.isAccept == true {
                if demoModeAtSyn {
                    print("accepted!")
                    print()
                }
        
                resultSyntaxs = resultSyntaxs.reversed()
                
                
                let indexResultSyntaxs = 0
                let resultTree: SyntaxTree = .init(head: resultSyntaxs[indexResultSyntaxs].lhs,
                                                   tree: resultSyntaxs[indexResultSyntaxs].rhs)
                
                for indexResultSyntaxs in 0..<resultSyntaxs.count {
                    resultTree.addRhsToTree(addFrom: resultSyntaxs[indexResultSyntaxs])
                }
                
                resultTree.setInput(input: inputTokens)
                
                return resultTree
            }
            if action.isShift {
                if demoModeAtSyn {
                  print("shift")
                }
                
                nowStatusStack.append(action.goTo)
                inputTokenIndex += 1
                
                
            } else {
                if demoModeAtSyn {
                    print("reduce")
                    print(syntaxAnalysisResources.definedSyntaxs[action.goTo])
                }
                
                resultSyntaxs.append(syntaxAnalysisResources.definedSyntaxs[action.goTo])
                for _ in 0..<syntaxAnalysisResources.definedSyntaxs[action.goTo].rhs.count {
                    guard nowStatusStack.popLast() != nil else {
                        return nil
                    }
                }
                guard let nowStatus = nowStatusStack.last else {
                    break
                }
                let getFromActionSheet = actionSheet.filter{ $0.input.isEqualAllowNilAsSame(to: syntaxAnalysisResources.definedSyntaxs[action.goTo].lhs) && $0.status == nowStatus }
                guard getFromActionSheet.count == 1, let action = getFromActionSheet.first else {
                    break
                }
                nowStatusStack.append(action.goTo)
            }
            if demoModeAtSyn {
                readLine()
            }
        }
        
        return nil
    }
    
    private func makeAutomata() -> [[SyntaxAnalysisResources.LR1Term]]? {
        var automatas: [[SyntaxAnalysisResources.LR1Term]] = []
        
        // オートマトン
        actionSheet = []
        
        // 初期ノードの作成
        guard let firstNode = syntaxAnalysisResources.calcClosureUnion(lhs: .start, rhs:  [TokenConstants.statement], point: 0, core: [TokenNode.`$`]) else {
            print("automata is not generated")
            return nil
        }
        automatas.append(firstNode)
        
        // 今の参照中のオーマトンのindex。automatasは変わるので、forでのイテレーションは絶対に駄目
        var indexAutomatas = 0
        while indexAutomatas < automatas.count {
            // 文法中に使われているTokenを見る
            for token in syntaxAnalysisResources.appearedTokenInSyntax {
                guard let gotoUnion = syntaxAnalysisResources.calcGotoUnion(lr1TermUnion: automatas[indexAutomatas], forcusToken: token) else {
                    print("automata is not generated")
                    return nil
                }
                
                if !gotoUnion.isEmpty
                    // Is not already added?
                    && automatas.reduce(true) { (result, arg) -> Bool in
                        return result && !syntaxAnalysisResources.isSameClosureUnion(arg, gotoUnion)
                    } {
                    automatas += [gotoUnion]
                }
            }
            indexAutomatas += 1
        }
        
        if demoModeAtSyn {
            print("automata count: ", automatas.count)
        }
        
        return automatas
    }
    
    /// 状態遷移表の作成
    private func makeActionSheet() {
        guard let automatas = makeAutomata() else {
            print("actionSheet is not generated")
            return
        }
        
        var indexAutomatas = 0
        while indexAutomatas < automatas.count {
            
            // 受理状態の追加
            for term in automatas[indexAutomatas] {
                if term.lhs == .start && term.point == term.rhs.count {
                    actionSheet.append((input: TokenNode.`$`, status: indexAutomatas, isShift: false, isAccept: true, goTo: -1))
                } else if term.point == term.rhs.count {
                    // Reduceの追加
                    let indexSameTerm = syntaxAnalysisResources.definedSyntaxs.index { arg -> Bool in
                        return arg.lhs == term.lhs
                            && syntaxAnalysisResources.isSameTokenRuleAllowNilAsSame(arg.rhs, term.rhs)
                    }
                    
                    guard let reduceTo = indexSameTerm else {
                        print("actionSheet is not generated")
                        return
                    }
                    
                    for core in term.core {
                        actionSheet.append((input: core, status: indexAutomatas, isShift: false, isAccept: false, goTo: Int(reduceTo)))
                    }
                }
            }
            
            // Shiftの追加
            for token in syntaxAnalysisResources.appearedTokenInSyntax {
                // tokenごとの遷移先を見る
                guard let gotoUnion = syntaxAnalysisResources.calcGotoUnion(lr1TermUnion: automatas[indexAutomatas], forcusToken: token) else {
                    continue
                }
                // Shift先の追加
                var shiftTo = 0
                for automata in automatas {
                    if syntaxAnalysisResources.isSameClosureUnion(automata, gotoUnion) {
                        self.actionSheet.append((input: token,
                                                 status: indexAutomatas,
                                                 isShift: true,
                                                 isAccept: false,
                                                 goTo: shiftTo))
                    }
                    shiftTo += 1
                }
            }
            indexAutomatas += 1
        }
        print("actionSheet is generated")
    }
}
