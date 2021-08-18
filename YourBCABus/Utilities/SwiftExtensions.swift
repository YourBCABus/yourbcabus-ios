//
//  SwiftExtensions.swift
//  SwiftExtensions
//
//  Created by Anthony Li on 8/18/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

extension RandomAccessCollection {
    func sorted<T: Comparable>(with mappingFunction: (Element) -> T) -> [Element] {
        sorted(by: { a, b in
            mappingFunction(a) < mappingFunction(b)
        })
    }
}
