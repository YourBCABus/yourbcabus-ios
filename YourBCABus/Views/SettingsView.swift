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
    @Binding var useFlyoverMap: Bool
    var dismiss: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("School")) {
                    NavigationLink("Change School", destination: SchoolsView(schoolID: $schoolID))
                    Text("School ID: \(schoolID ?? "None")")
                }
                
                Section(header: Text("Notifications")) {
                    let toggle = Toggle("Starred Buses", isOn: $busArrivalNotifications)
                    if #available(iOS 15.0, *) {
                        toggle.tint(Color.accentColor)
                    } else {
                        toggle
                    }
                }
                
                Section(header: Text("Map")) {
                    let toggle = Toggle("Use 3D Satellite Map", isOn: $useFlyoverMap)
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
