//
//  AlertView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/8/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

extension GetBusesQuery.Data.School.Alert {
    var highlightColor: Color {
        if let color = type?.color {
            return Color(red: Double(color.r) / 255, green: Double(color.g) / 255, blue: Double(color.b) / 255)
        } else {
            return .accentColor
        }
    }
}

struct AlertView: View {
    var alert: GetBusesQuery.Data.School.Alert
    var isActive: Bool
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            if let type = alert.type, let name = type.name {
                Text(name).font(.caption).fontWeight(.bold).textCase(.uppercase).padding(.vertical, 4).padding(.horizontal, 8).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading).background(alert.highlightColor).foregroundColor(.white)
            }
            HStack {
                Text(alert.title).multilineTextAlignment(.leading).foregroundColor(.primary)
                Spacer()
                if alert.dismissable {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }.accessibility(label: Text("Dismiss"))
                }
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }.padding([.horizontal, .bottom], 8)
        }.frame(maxWidth: .infinity, alignment: .leading).background( alert.highlightColor.opacity(isActive ? 0.4 : 0.2)).cornerRadius(8)
    }
}

struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView(alert: GetBusesQuery.Data.School.Alert(id: "f", start: "0", end: "1", title: "sdf", type: nil, dismissable: false), isActive: false) {}.padding()
    }
}
