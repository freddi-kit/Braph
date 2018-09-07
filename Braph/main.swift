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
    
    while true {
        // Input from command line
        print(": >>", terminator: " ")
        guard let inputFromInterprit = readLine() else {
            break
        }
        
        // Lexical Analysis
        let lexs = lexicalAnalysis.analysis(input: inputFromInterprit)
        
        if let lexs = lexs {
            for lex in lexs {
                print(lex)
            }
        } else {
            print("lexical Error")
        }
    }
}

main()


