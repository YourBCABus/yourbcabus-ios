//
//  PhoneNumbers.swift
//  YourBCABus
//
//  Created by Anthony Li on 1/17/22.
//  Copyright © 2022 YourBCABus. All rights reserved.
//

import Foundation

// Porting this was not a breeze.

let phoneRegex = try! NSRegularExpression(pattern: #"(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *(?:x|ext|#)\.? *(\d+))?"#, options: [])

func matchToFormattedString(string: String, match: NSTextCheckingResult) -> String {
    let strings = (0..<match.numberOfRanges).map { i in
        Range(match.range(at: i), in: string).map { String(string[$0]) }
    }
    
    var result = "+\(strings[1] ?? "1") \(strings[2]!)-\(strings[3]!)-\(strings[4]!)"
    if let ext = strings[5] {
        result += " ext. \(ext)"
    }
    
    return result
}

func formatNumbers(in phoneNumbers: String) -> [String] {
    phoneRegex.matches(in: phoneNumbers, options: [], range: NSRange(phoneNumbers.startIndex..<phoneNumbers.endIndex, in: phoneNumbers)).map { matchToFormattedString(string: phoneNumbers, match: $0) }
}
