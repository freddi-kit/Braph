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


if let a = SyntaxAnalysisResources.calcClosureUnion(lhs: .expr, rhs: [TokenConstants.expr, TokenNode.operant(.plus, nil), TokenConstants.term], point: 0)
{
    for i in a {
        print(i)
    }
    print()
    
    if let b = SyntaxAnalysisResources.calcGotoUnion(i: a, forcusToken: TokenNode.identifier(nil)) {
        print(b)
        for j in b {
            print(j)
        }
        print()
    }
}


//if let union = SyntaxAnalysisResources.calcClosureUnion(lhs: .define, rhs: [TokenNode.keyword(.define, nil), TokenNode.identifier(nil), TokenNode.symbol("="),  TokenConstants.expr], point: 2) {
//    for i in union {
//        print(i)
//    }
//    print()
//    for i in SyntaxAnalysisResources.calcGotoUnion(i: union, forcusToken: TokenNode.symbol("="))! {
//        print(i)
//    }
//}

main()


