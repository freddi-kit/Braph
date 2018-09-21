//
//  main.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/08/25.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation


func main(){
    let lexicalAnalysis = LexicalAnalysis()
    let syntaxAnalysis = SyntaxAnalysis()
    let semanticsAnalysis = SemanticsAnalysis()
    
    var syntaxResults: [SyntaxTree] = []
    
    while true {
        // Input from command line
        print(": >>", terminator: " ")
        
        // Lexical Analysis
        if let inputFromInterprit = readLine(),
            let lexs = lexicalAnalysis.analysis(input: inputFromInterprit) {
            guard inputFromInterprit != "" else {
                break
            }
            
            if let syntaxTree = syntaxAnalysis.analysis(input: lexs) {
                syntaxTree.printTree()
                syntaxResults.append(syntaxTree)
            } else {
                print("syntax Error")
            }
            
        } else {
            print("lexical Error")
        }
    }
    
    semanticsAnalysis.analysis(input: syntaxResults)
}

main()


