//
//  main.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

let lexs = lexicalAnalysis("Int  Int  ")
if let lexs = lexs {
    for lex in lexs {
        print(lex)
    }
} else {
    print("lexical Error")
}

