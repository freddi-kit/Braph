//
//  SyntaxAnalysisFunctionTests.swift
//  BraphTests
//
//  Created by 秋勇紀 on 2018/11/03.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import XCTest

// https://www.slideshare.net/ichikaz3/lr-parsing
class SyntaxAnalysisFunctionTests: XCTestCase {
    
    private let syntaxResources = SyntaxAnalysisResources(definedSyntaxs: [
        (lhs: .S, rhs: [TokenConstants.A]),
        (lhs: .A, rhs: [TokenConstants.E, TokenNode.symbol("="), TokenConstants.E]),
        (lhs: .A, rhs: [TokenNode.identifier(nil)]),
        (lhs: .E, rhs: [TokenConstants.E, TokenNode.operant(.plus, nil), TokenConstants.T]),
        (lhs: .E, rhs: [TokenConstants.T]),
        (lhs: .T, rhs: [TokenNode.identifier(nil)]),
        (lhs: .T, rhs: [TokenNode.literal(nil, nil)]),
        (lhs: .U, rhs: [TokenConstants.V]),
        (lhs: .V, rhs: []),
        ]
    )
    
    func testCalcGotoUnion() {
        
    }
    

    func testIsTokenHaveNullRule() {
        XCTAssertFalse(syntaxResources.isTokenHaveNullRule(token: TokenConstants.S))
        XCTAssertFalse(syntaxResources.isTokenHaveNullRule(token: TokenConstants.A))
        XCTAssertFalse(syntaxResources.isTokenHaveNullRule(token: TokenConstants.E))
        XCTAssertFalse(syntaxResources.isTokenHaveNullRule(token: TokenConstants.T))
        
        XCTAssertTrue(syntaxResources.isTokenHaveNullRule(token: TokenConstants.U))
        XCTAssertTrue(syntaxResources.isTokenHaveNullRule(token: TokenConstants.V))
    }
    
    func testCalcFirstUnion() {
        let resultA = syntaxResources.calcFirstUnion(token: TokenConstants.S)
        let answerA: [TokenNode] = [TokenNode.identifier(nil), TokenNode.literal(nil, nil)]
        XCTAssertTrue(syntaxResources.isSameTokenArrayAllowNilAsSame(resultA, answerA))
        
        let resultB = syntaxResources.calcFirstUnion(token: TokenConstants.U)
        let answerB: [TokenNode] = []
        XCTAssertTrue(syntaxResources.isSameTokenArrayAllowNilAsSame(resultB, answerB))
    }
    
    func testCalcFollowUnion() {
        // TODO
    }
    
    
    func testMakeUnion() {
        let arrayTestA: [Token] = [
            TokenConstants.A,
            TokenConstants.A,
            TokenNode.identifier("nyan"),
            TokenNode.identifier("mike"),
            TokenConstants.A
        ]
        let resultA = syntaxResources.makeUnion(array: arrayTestA)
        let answerA: [Token] = [TokenConstants.A, TokenNode.identifier("nyan"), TokenNode.identifier("mike")]
        XCTAssertTrue(syntaxResources.isSameTokenArrayAllowNilAsSame(resultA, answerA))
        
        let arrayTestB: [SyntaxAnalysisResources.LR0Term] = [
            (lhs: TokenConstants.A, rhs: [TokenConstants.E, TokenNode.symbol("="), TokenConstants.E], point: 0),
            (lhs: TokenConstants.A, rhs: [TokenConstants.E, TokenNode.symbol("="), TokenConstants.E], point: 1),
            (lhs: TokenConstants.A, rhs: [TokenConstants.E, TokenNode.symbol("="), TokenConstants.E], point: 0)
        ]
        
        let resultB = syntaxResources.makeUnion(array: arrayTestB)
        let answerB: [SyntaxAnalysisResources.LR0Term] = [
            (lhs: TokenConstants.A, rhs: [TokenConstants.E, TokenNode.symbol("="), TokenConstants.E], point: 0),
            (lhs: TokenConstants.A, rhs: [TokenConstants.E, TokenNode.symbol("="), TokenConstants.E], point: 1)
        ]
        
        XCTAssertTrue(syntaxResources.isSameClosureUnion(resultB, answerB))
    }
}
