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
    
    while true {
        // Input from command line
        print(": >>", terminator: " ")
        
        // Lexical Analysis
        if let inputFromInterprit = readLine(),
            let lexs = lexicalAnalysis.analysis(input: inputFromInterprit) {
            print(lexs)
            
            if let syntaxTree = syntaxAnalysis.analysis(input: lexs) {
                print(syntaxTree)
            } else {
                print("syntax Error")
            }
        } else {
            print("lexical Error")
            
        }
    }
}

print(SyntaxTree.TokenConstants.expr)
for i in SyntaxTree.calcFollowUnion(token: SyntaxTree.TokenConstants.expr) {
    print(i)
}

print(SyntaxTree.TokenConstants.term)
for i in SyntaxTree.calcFollowUnion(token: SyntaxTree.TokenConstants.term) {
    print(i)
}

print(SyntaxTree.TokenConstants.factor)
for i in SyntaxTree.calcFollowUnion(token: SyntaxTree.TokenConstants.factor) {
    print(i)
}

main()


