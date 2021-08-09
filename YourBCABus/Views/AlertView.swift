//
//  AlertView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/8/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct AlertView: View {
    var alert: GetBusesQuery.Data.School.Alert
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            if let type = alert.type, let name = type.name {
                Text(name).font(.caption).fontWeight(.bold).textCase(.uppercase).padding(.vertical, 4).padding(.horizontal, 8).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading).background(Color.accentColor).foregroundColor(.white)
            }
            HStack {
                Text(alert.title).multilineTextAlignment(.leading)
                if alert.dismissable {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }.accessibility(label: Text("Dismiss"))
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                }
            }.padding([.horizontal, .bottom], 8)
        }.frame(maxWidth: .infinity, alignment: .leading).background(Color.primary.opacity(0.1)).cornerRadius(8)
    }
}

struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView(alert: GetBusesQuery.Data.School.Alert(id: "f", start: "0", end: "1", title: "sdf", type: nil, dismissable: false)) {}.padding()
    }
}
