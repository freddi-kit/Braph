//
//  SemanticsAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/21.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

class SemanticsAnalysis {
    
    var shift = 0
    var valueTable:[String: (Int, String)] = [:]
    var resultCode: String = "define i32 @main() {\n"
    
    public func analysis(input syntaxTree: SyntaxTree) -> [String]? {
        if syntaxTree.head == .statement {
            for node in syntaxTree.tree {
                if let nodeTree = node as? SyntaxTree {
                    switch nodeTree.head {
                    case .declaration:
                        if let node =  nodeTree.tree[1] as? TokenNode {
                            switch node {
                            case .identifier(let name):
                                if let name = name {
                                    if let node =  nodeTree.tree[2] as? SyntaxTree{
                                        if let node = node.tree[1] as? SyntaxTree,
                                        let value = calcExpr(tree: node) {
                                            shift += 1
                                            valueTable[name] = (shift, value)
                                            resultCode += "\t%\(shift) = alloca i32, align 4\n"
                                            resultCode += "\tstore i32 \(value), i32* %\(shift), align 4\n"

                                        }
                                    }
                                }
                            default: return nil
                            }
                        }
                    case .expr:
                        if let value = calcExpr(tree: nodeTree) {
                        }
                    case .return:
                        if let valueNode = nodeTree.tree[1] as? TokenNode {
                            switch valueNode {
                            case .identifier(let name):
                                if let name = name, let valueData = valueTable[name]{
                                    resultCode += "\t%\(shift+1) = load i32, i32* %\(valueData.0), align 4\n"
                                    resultCode += "\tret i32 %\(shift+1)\n"
                                }
                                return nil
                            default: return nil
                            }
                            
                        }
                    default: break
                    }
                }
            }
        }
            
        if demoModeAtSem {
            print(valueTable)
        }
        
        return nil
    }
    
    
    func calcExpr(tree: SyntaxTree) -> String? {
        var resultReturn: String = ""
        for checkNode in tree.tree {
            if let checkNodeCasted = checkNode as? SyntaxTree {
                if checkNodeCasted.head == .expr ||
                    checkNodeCasted.head == .term {
                    guard let result = calcExpr(tree: checkNodeCasted) else {
                        return nil
                    }
                    resultReturn += result
                }
                else if checkNodeCasted.head == .factor {
                    guard let factor = checkNodeCasted.tree[0] as? TokenNode else {
                        return nil
                    }
                    switch factor {
                    case .literal(_, let value):
                        if let value = value {
                            return value
                        }
                    default:
                        return nil
                    }
                }
            }
        }
        return resultReturn
    }
}
