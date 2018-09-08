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
    
    required init(type: [DetectingType], count: Int) {
        self.type = type
        self.count = count
    }
    
    enum DetectingType {
        case int
        case double
        case string
        case intaractive
        case `var`
        case `let`
    }
    let type: [DetectingType]
    let count: Int
    
}

class QForIndetifier: Q {
}

class QForSymbol: Q {
}
