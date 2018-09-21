//
//  SyntaxAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/09.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

class SyntaxAnalysis {
    private var actionSheet: [(input: Token, status: Int, isShift: Bool, isAccept: Bool, goTo: Int)] = []
    
    init() {
        makeAutomatasAndActionSheet()
        for i in actionSheet {
            print(i)
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
            guard let nowStatus = nowStatusStack.last else {
                break
            }
            
            let getFromActionSheet = actionSheet.filter{ $0.input.isEqualAllowNilAsSame(to: inputToken) && $0.status == nowStatus }
            
            guard let action = getFromActionSheet.first else {
                return nil
            }
            if action.isAccept == true {
                print("accepted!")
                let resultTree: SyntaxTree = .init([])
                for resultSyntax in resultSyntaxs.reversed() {
                    resultTree.addRhsToTree(addFrom: resultSyntax)
                }
                resultTree.setInput(input: inputTokens)
                return resultTree
            }
            if action.isShift {
                print("shift")
                nowStatusStack.append(action.goTo)
                inputTokenIndex += 1
                print("shift done")
                
            } else {
                print("reduce")
                resultSyntaxs.append(SyntaxAnalysisResources.definedSyntaxs[action.goTo])
                for _ in 0..<SyntaxAnalysisResources.definedSyntaxs[action.goTo].rhs.count {
                    guard nowStatusStack.popLast() != nil else {
                        print("cannot pop")
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
                print("reduce done")
            }
        }
        
        return nil
    }
    
    /// 状態遷移表等々の作成
    private func makeAutomatasAndActionSheet() {
        var automatas: [[SyntaxAnalysisResources.LR1Term]] = []
        actionSheet = []
        
        guard let firstUnion = SyntaxAnalysisResources.calcClosureUnion(lhs: .start, rhs:  [TokenConstants.statement], point: 0, core: [TokenNode.`$`]) else {
            print("actionSheet is not generated")
            return
        }
        
        automatas.append(firstUnion)
                
        var nowStatus = 0
        while nowStatus < automatas.count {
            for token in SyntaxAnalysisResources.appearedTokenInSyntax {
                guard let gotoUnion = SyntaxAnalysisResources.calcGotoUnion(i: automatas[nowStatus], forcusToken: token) else {
                    continue
                }
                if !gotoUnion.isEmpty
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
                if term.lhs == .start && term.point == term.rhs.count {
                    actionSheet.append((input: TokenNode.`$`, status: nowStatus, isShift: false, isAccept: true, goTo: -1))
                }
                
                if term.point == term.rhs.count {
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
                guard let gotoUnion = SyntaxAnalysisResources.calcGotoUnion(i: automata, forcusToken: token) else {
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
