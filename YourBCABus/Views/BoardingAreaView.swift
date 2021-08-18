//
//  BoardingAreaView.swift
//  BoardingAreaView
//
//  Created by Anthony Li on 8/18/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct BoardingAreaView: View {
    var boardingArea: String?
    
    init(_ boardingArea: String?) {
        self.boardingArea = boardingArea
    }
    
    var body: some View {
        ZStack {
            if let area = boardingArea {
                Circle().fill(Color.accentColor)
                Text(area).foregroundColor(.white).fontWeight(.bold)
            } else {
                Circle().stroke(Color.accentColor)
                Text("?").foregroundColor(.primary).fontWeight(.bold)
            }
        }.multilineTextAlignment(.center).aspectRatio(1, contentMode: .fit)
    }
}
