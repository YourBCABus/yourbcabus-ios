//
//  FooterView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct FooterView: View {
    var body: some View {
        Link(destination: URL(string: "https://about.yourbcabus.com")!) {
            VStack {
                Text("The YourBCABus Team").font(.headline)
                Text("Anthony Li, Edward Feng, Skyler Calaman").font(.caption)
            }.multilineTextAlignment(.center).foregroundColor(.secondary)
        }
    }
}
