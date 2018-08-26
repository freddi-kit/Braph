//
//  Automaton.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

enum Node {
    case start(Int)
    case normal(Int)
    case accept(Int, Token)
    case undefined
}

func automataChecker(_ q: Int, _ input: String) -> Node {
    // TypeCheck
    
}
