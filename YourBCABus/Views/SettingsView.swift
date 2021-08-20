//
//  SettingsView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Binding var schoolID: String?
    @Binding var busArrivalNotifications: Bool
    var dismiss: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(schoolID ?? "School")) {
                    NavigationLink("Change School", destination: SchoolsView(schoolID: $schoolID))
                }
                
                Section(header: Text("Notifications")) {
                    let toggle = Toggle("Starred Buses", isOn: $busArrivalNotifications)
                    if #available(iOS 15.0, *) {
                        toggle.tint(Color.accentColor)
                    } else {
                        toggle
                    }
                }
            }.navigationBarTitle("Settings", displayMode: .inline).toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
