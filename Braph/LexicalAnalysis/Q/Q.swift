//
//  Q.swift
//  Braph
//
//  Created by 秋勇紀 on 2018/09/09.
//  Copyright © 2018 勇者野良猫の部屋. All rights reserved.
//

import Foundation

/// オートマトンの状態プロトコル
protocol Q {
}

class QForStarter: Q {
}

class QForSeparator: Q {
}

class QKeyWord: Q {
    
    required init(typeStack: [DetectingToken], count: Int) {
        self.type = typeStack
        self.count = count
    }
    
    enum DetectingToken {
        case `Int`
        case `Double`
        case `String`
        case `Intaractive`
        case `var`
        case `let`
        case `func`
        case `return`
    }
    
    let type: [DetectingToken]
    let count: Int
}

class QForIndetifier: Q {
}

class QForSymbol: Q {
}

class QForNumericLiteral: Q {
    
    required init(type: Token.LiteralType) {
        self.type = type
    }
    
    let type: Token.LiteralType
}

class QForStringLiteral: Q {
}

class QForDeadStatus: Q {
}
