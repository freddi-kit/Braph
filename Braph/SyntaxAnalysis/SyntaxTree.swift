//
//  SyntaxTree.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/21.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

// MARK: 構文木
class SyntaxTree: Token {
    
    // MARK: Initialization
    
    init(head: TokenConstants, tree: [Token]) {
        self.tree = tree
        self.head = head
    }
    
    // MARK: Public Values
    // 木構造
    public var tree: [Token]
    public var head: TokenConstants
    
    private func showDepthTabSpace(depth: Int) {
        if depth != 0 {
            for _ in 0..<depth {
                print(" ", terminator: "")
            }
        }
    }

    /// 木構造表示
    public func printTree(){
        inlinePrintTree()
    }
    
    /// 木構造表示(中での処理)
    private func inlinePrintTree(depth: Int = 0) {
        showDepthTabSpace(depth: depth)
        print(self.head)
        for node in tree {
            if let insideTree = node as? SyntaxTree {
                insideTree.inlinePrintTree(depth: depth + 1)
            } else {
                showDepthTabSpace(depth: depth+1)
                print(node)
            }
        }
    }
    
    /// 解析の結果を木構造に打ち込む
    public func addRhsToTree(addFrom: SyntaxAnalysisResources.GenerateRule) {
        if tree.count == 0 {
            tree = addFrom.rhs
        } else {
            for treeIndex in 0..<tree.count {
                if let subTree = tree[treeIndex] as? SyntaxTree {
                    subTree.addRhsToTree(addFrom: addFrom)
                }
                if tree[treeIndex].isEqualAllowNilAsSame(to: addFrom.lhs) {
                    tree[treeIndex] = SyntaxTree.init(head: addFrom.lhs, tree: addFrom.rhs)
                }
            }
        }
    }
    
    /// TokenNodeに具体的な値を入れる
    /// TODO: 流石にひどいので改善
    private static var insideIndex = 0
    public func setInput(input: [TokenNode]){
        for index in 0..<tree.count {
            if let insideTree = tree[index] as? SyntaxTree {
                insideTree.setInput(input: input)
            } else {
                if tree[index] is TokenNode {
                    tree[index] = input[SyntaxTree.insideIndex]
                    SyntaxTree.insideIndex += 1
                    if SyntaxTree.insideIndex == input.count - 1  {
                        SyntaxTree.insideIndex = 0
                    }
                }
            }
        }
    }
    
}

