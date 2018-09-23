//
//  main.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

let demoModeAtLex = false
let demoModeAtSyn = false
let demoModeAtSem = true


func main(){
    let lexicalAnalysis = LexicalAnalysis()
    let syntaxAnalysis = SyntaxAnalysis()
    let semanticsAnalysis = SemanticsAnalysis()
    
    while true {
        // Input from command line
        print(": >>", terminator: " ")
        
        // Lexical Analysis
        guard let inputFromInterprit = readLine() else {
            print("\nInput End!")
            break
        }
        
        guard let lexs = lexicalAnalysis.analysis(input: inputFromInterprit) else {
            print("Lexical Error!")
            continue
        }
        if demoModeAtLex {
            print(lexs)
        }
        
        guard let syntaxTree = syntaxAnalysis.analysis(input: lexs) else {
            print("Syntax Error!")
            continue
        }
        if demoModeAtSyn {
            syntaxTree.printTree()
        }
            
        guard let absoluteSyntaxTree = semanticsAnalysis.analysis(input: syntaxTree) else {
            print("Semantics Error")
            continue
        }
    }
    if demoModeAtSem {
        print(semanticsAnalysis.resultCode + "}")
    }
}

main()


