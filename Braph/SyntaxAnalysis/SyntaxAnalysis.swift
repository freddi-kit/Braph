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
    }
    
    // MARK: Public functions
    
    /// 構文解析
    public func analysis(input inputTokens:[TokenNode]) -> SyntaxTree? {
        var nowStatusStack: [Int] = [0]
        var inputTokenIndex = 0
        var resultSyntaxs: [SyntaxAnalysisResources.GenerateRule] = []
        
        
        while inputTokenIndex < inputTokens.count {
            
            let inputToken = inputTokens[inputTokenIndex]
            guard let nowStatus = nowStatusStack.last else {
                break
            }
            
            let getFromActionSheet = actionSheet.filter{ $0.input.isEqualAllowNilAsSame(to: inputToken) && $0.status == nowStatus }
            
            guard let action = getFromActionSheet.first else {
                return nil
            }
            
            if demoModeAtSyn {
                print(action)
                readLine()
            }
            
            
            if action.isAccept == true {
                if demoModeAtSyn {
                    print("accepted!")
                    print()
                }
        
                
                resultSyntaxs = resultSyntaxs.reversed()
                let resultIndex = 0
                let resultTree: SyntaxTree = .init(head: resultSyntaxs[resultIndex].lhs, tree: resultSyntaxs[resultIndex].rhs)
                
                for resultIndex in 0..<resultSyntaxs.count {
                    resultTree.addRhsToTree(addFrom: resultSyntaxs[resultIndex])
                }
                resultTree.setInput(input: inputTokens)
                print(resultTree.printTree())
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
                    break
                }
                nowStatusStack.append(action.goTo)
            }
        }
        
        return nil
    }
    
    /// 状態遷移表の作成
    private func makeAutomatasAndActionSheet() {
        // オートマトン
        var automatas: [[SyntaxAnalysisResources.LR1Term]] = []
        actionSheet = []
        
        // 初期ノードの作成
        guard let firstNode = SyntaxAnalysisResources.calcClosureUnion(lhs: .start, rhs:  [TokenConstants.statement], point: 0, core: [TokenNode.`$`]) else {
            print("actionSheet is not generated")
            return
        }
        automatas.append(firstNode)
        
        // 今の参照中のオーマトン
        // automatasは変わるので、forでのイテレーションは絶対に駄目
        var nowStatus = 0
        while nowStatus < automatas.count {
            // 文法中に使われているTokenを見る
            for token in SyntaxAnalysisResources.appearedTokenInSyntax {
                guard let gotoUnion = SyntaxAnalysisResources.calcGotoUnion(lr1TermUnion: automatas[nowStatus], forcusToken: token) else {
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
            nowStatus += 1
        }
        
        nowStatus = 0
        for automata in automatas {
            for term in automata {
                // 受理行動状態の追加
                if term.lhs == .start && term.point == term.rhs.count {
                    actionSheet.append((input: TokenNode.`$`, status: nowStatus, isShift: false, isAccept: true, goTo: -1))
                } else if term.point == term.rhs.count {
                    var processTimes = 0
                    for syntax in SyntaxAnalysisResources.definedSyntaxs {
                        if syntax.lhs == term.lhs && SyntaxAnalysisResources.isSameTokenArrayAllowNilAsSame(term.rhs, syntax.rhs) {
                            break
                        }
                        processTimes += 1
                    }
                    for core in term.core {
                        actionSheet.append((input: core, status: nowStatus, isShift: false, isAccept: false, goTo: processTimes))
                    }
                }
            }
            for token in SyntaxAnalysisResources.appearedTokenInSyntax {
                guard let gotoUnion = SyntaxAnalysisResources.calcGotoUnion(lr1TermUnion: automata, forcusToken: token) else {
                    continue
                }
                var processTimes = 0
                for automata in automatas {
                    if SyntaxAnalysisResources.isSameClosureUnion(i1: automata, i2: gotoUnion) {
                        self.actionSheet.append((input: token, status: nowStatus, isShift: true, isAccept: false, goTo: processTimes))
                    }
                    processTimes += 1
                }
            }
            nowStatus += 1
        }
        print("actionSheet is generated")
    }
}
