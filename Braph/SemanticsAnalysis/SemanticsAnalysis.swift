//
//  SemanticsAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/21.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

class SemanticsAnalysis {
    
    
    public func analysis(input syntaxTrees: [SyntaxTree]) -> [String]? {
        for syntaxTree in syntaxTrees {
            syntaxTree.printTree()
            
            if syntaxTree.head == .statement {
                for node in syntaxTree.tree {
                    if let nodeTree = node as? SyntaxTree {
                        switch nodeTree.head {
                        case .declaration:
                            print("declaration")
                        case .return:
                            print("return")
                        default: break
                        }
                    }
                }
            }
            
        }
        return nil
    }
}
