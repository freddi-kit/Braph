//
//  SyntaxAnalysis.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/09.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

class SyntaxAnalysis {
    
    // MARK: Public functions
    public func analysis(input :[TokenNode]) -> SyntaxTree? {
        return nil
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
