//
//  ContentView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/2/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Binding var schoolID: String?
    @State var settingsVisible = false
    
    var body: some View {
        Group {
            if let id = schoolID {
                NavigationView {
                    BusesView(schoolID: id).edgesIgnoringSafeArea(.all).navigationTitle("YourBCABus").toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                settingsVisible = true
                            } label: {
                                Label("Settings", systemImage: "gear")
                            }
                        }
                    }
                    Text("Detail view")
                }
            } else {
                EmptyView()
            }
        }.sheet(isPresented: .constant(schoolID == nil)) {
            if #available(iOS 15.0, *) {
                OnboardingView(schoolID: $schoolID).interactiveDismissDisabled()
            } else {
                OnboardingView(schoolID: $schoolID).undismissable()
            }
        }.sheet(isPresented: $settingsVisible) {
            SettingsView(schoolID: $schoolID) {
                settingsVisible = false
            }
        }
    }
}
