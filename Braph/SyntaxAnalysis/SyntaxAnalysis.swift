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
    
    // 状態遷移表
    private var actionSheet: [(input: Token, status: Int, isShift: Bool, isAccept: Bool, goTo: Int)] = []
    
    // MARK: Initializer
    
    init() {
        makeAutomatasAndActionSheet()
        if demoModeAtSyn {
            for action in actionSheet {
                print(action)
            }
        }
    }
    
    // MARK: Public functions
    
    /// 構文解析
    public func analysis(input inputTokens:[TokenNode]) -> SyntaxTree? {
        var nowStatusStack: [Int] = [0]
        var inputTokenIndex = 0
        var resultSyntaxs: [SyntaxAnalysisResources.GenerateRule] = []
        
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
                }
                print(SyntaxAnalysisResources.definedSyntaxs[action.goTo])
                resultSyntaxs.append(SyntaxAnalysisResources.definedSyntaxs[action.goTo])
                for _ in 0..<SyntaxAnalysisResources.definedSyntaxs[action.goTo].rhs.count {
                    guard nowStatusStack.popLast() != nil else {
                        return nil
                    }
                }
                guard let nowStatus = nowStatusStack.last else {
                    break
                }
                let getFromActionSheet = actionSheet.filter{ $0.input.isEqualAllowNilAsSame(to: SyntaxAnalysisResources.definedSyntaxs[action.goTo].lhs) && $0.status == nowStatus }
                guard getFromActionSheet.count == 1, let action = getFromActionSheet.first else {
                    print("many status!")
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
    
    /// 状態遷移表の作成
    private func makeAutomatasAndActionSheet() {
        
        var automatas: [[SyntaxAnalysisResources.LR1Term]] = []

        // オートマトン
        actionSheet = []
        
        // 初期ノードの作成
        guard let firstNode = SyntaxAnalysisResources.calcClosureUnion(lhs: .S, rhs:  [TokenConstants.A], point: 0, core: [TokenNode.`$`]) else {
            print("actionSheet is not generated")
            return
        }
        automatas.append(firstNode)
        
        // 今の参照中のオーマトンのindex。automatasは変わるので、forでのイテレーションは絶対に駄目
        var indexAutomatas = 0
        while indexAutomatas < automatas.count {
            // 文法中に使われているTokenを見る
            for token in SyntaxAnalysisResources.appearedTokenInSyntax {
                guard let gotoUnion = SyntaxAnalysisResources.calcGotoUnion(lr1TermUnion: automatas[indexAutomatas], forcusToken: token) else {
                    print("actionSheet is not generated")
                    return
                }
                
                if !gotoUnion.isEmpty
                    // Is not already added?
                    && automatas.reduce(true) { (result, arg) -> Bool in
                        return result && !SyntaxAnalysisResources.isSameClosureUnion(i1: arg, i2: gotoUnion)
                    } {
                    automatas += [gotoUnion]
                }
            }
            indexAutomatas += 1
        }
        
        // Shiftの追加
        indexAutomatas = 0
        while indexAutomatas < automatas.count {
            
            // 受理状態の追加
            for term in automatas[indexAutomatas] {
                if term.lhs == .S && term.point == term.rhs.count {
                    actionSheet.append((input: TokenNode.`$`, status: indexAutomatas, isShift: false, isAccept: true, goTo: -1))
                } else if term.point == term.rhs.count {
                    // Reduceの追加
                    let indexSameTerm = SyntaxAnalysisResources.definedSyntaxs.index { arg -> Bool in
                        return arg.lhs == term.lhs
                            && SyntaxAnalysisResources.isSameTokenArrayAllowNilAsSame(arg.rhs, term.rhs)
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
            
            for token in SyntaxAnalysisResources.appearedTokenInSyntax {
                // tokenごとの遷移先を見る
                guard let gotoUnion = SyntaxAnalysisResources.calcGotoUnion(lr1TermUnion: automatas[indexAutomatas], forcusToken: token) else {
                    continue
                }
                // Shift先の追加
                var shiftTo = 0
                for automata in automatas {
                    if SyntaxAnalysisResources.isSameClosureUnion(i1: automata, i2: gotoUnion) {
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
