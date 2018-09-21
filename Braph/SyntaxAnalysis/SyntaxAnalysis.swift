//
//  SyntaxAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/09.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

class SyntaxAnalysis {
    private var automatas: [[SyntaxAnalysisResources.LR1Term]] = []
    private var actionSheet: [(input: Token, status: Int, isShift: Bool, isAccept: Bool, goTo: Int)] = []
    
    init() {
        makeAutomatas()
        for i in actionSheet {
            print(i)
        }
    }
    
    // MARK: Public functions
    public func analysis(input inputTokens:[TokenNode]) -> SyntaxTree? {
        var nowStatusStack: [Int] = [0]
        var inputTokenIndex = 0
        var result: [Int] = []
        var resultTree: SyntaxTree = .init([])
        
        while inputTokenIndex < inputTokens.count {
            let inputToken = inputTokens[inputTokenIndex]
            guard let nowStatus = nowStatusStack.last else {
                print("no stack")
                break
            }
            
            _ = readLine()
            
            print("input is" ,inputToken)
            print("now is" ,nowStatus)
            let getFromActionSheet = actionSheet.filter{ $0.input.isEqualAllowNilAsSame(to: inputToken) && $0.status == nowStatus }
            print("action is" ,getFromActionSheet)
            if let action = getFromActionSheet.first {
                if action.isAccept == true {
                    print("accepted!")
                    return resultTree
                }
                if action.isShift {
                    print("shift")
                    nowStatusStack.append(action.goTo)
                    inputTokenIndex += 1
                    print("shift done")
                } else {
                    print("reduce to", SyntaxAnalysisResources.definedSyntaxs[action.goTo])
                    result.append(action.goTo)
                    for _ in 0..<SyntaxAnalysisResources.definedSyntaxs[action.goTo].rhs.count {
                        guard let _ = nowStatusStack.popLast() else {
                            print("cannot pop")
                            return nil
                        }
                    }
                    guard let nowStatus = nowStatusStack.last else {
                        print("cannot see last")
                        return nil
                    }
                    let getFromActionSheet = actionSheet.filter{ $0.input.isEqualAllowNilAsSame(to: SyntaxAnalysisResources.definedSyntaxs[action.goTo].lhs) && $0.status == nowStatus }
                    guard getFromActionSheet.count == 1, let action = getFromActionSheet.first else {
                        print("there is no action")
                        return nil
                    }
                    nowStatusStack.append(action.goTo)
                    print("reduce done")
                }
            } else {
                print("there is no action")
                return nil
            }
        }
        print("reading over")
        return nil
    }
    
    private func makeAutomatas() {
        automatas = []
        actionSheet = []
        
        guard let firstQ = SyntaxAnalysisResources.calcClosureUnion(lhs: .start, rhs:  [TokenConstants.statement], point: 0, core: [TokenNode.`$`]) else {
            print("actionSheet is not generated")
            return
        }
        
        automatas.append(firstQ)
                
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
                    var count = 0
                    for syntax in SyntaxAnalysisResources.definedSyntaxs {
                        if syntax.lhs == term.lhs && SyntaxAnalysisResources.isSameTokenArrayAllowNilAsSame(term.rhs, syntax.rhs) {
                            break
                        }
                        count += 1
                    }
                    for core in term.core {
                        actionSheet.append((input: core, status: nowStatus, isShift: false, isAccept: false, goTo: count))
                    }
                }
            }
            for token in SyntaxAnalysisResources.appearedTokenInSyntax {
                guard let gotoUnion = SyntaxAnalysisResources.calcGotoUnion(i: automata, forcusToken: token) else {
                    continue
                }
                var count = 0
                for automata in automatas {
                    if SyntaxAnalysisResources.isSameClosureUnion(i1: automata, i2: gotoUnion) {
                        self.actionSheet.append((input: token, status: nowStatus, isShift: true, isAccept: false, goTo: count))
                    }
                    count += 1
                }
            }
            nowStatus += 1
        }
        print("actionSheet is not generated")
    }
}

// 構文木
class SyntaxTree: Token {
    
    // MARK: Initialization
    
    init(_ nodes: [Token]) {
        self.nodes = nodes
    }
    
    // MARK: Public Values
    
    public var nodes: [Token]
}
