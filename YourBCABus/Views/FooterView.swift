//
//  FooterView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct FooterView: View {
    static let names = "\(["Skyler Calaman", "Edward Feng", "Anthony Li", "Yusuf Sallam", "Alice Zhang"].shuffled().joined(separator: ", ")), et al"
    
    var body: some View {
        Link(destination: URL(string: "https://about.yourbcabus.com")!) {
            VStack {
                Text("The YourBCABus Team").font(.headline)
                Text(Self.names).font(.caption)
            }.multilineTextAlignment(.center).foregroundColor(.secondary)
        }
    }
}
