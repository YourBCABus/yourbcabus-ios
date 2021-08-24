//
//  SettingsView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import Apollo

struct SettingsView: View {
    @Binding var schoolID: String?
    @Binding var busArrivalNotifications: Bool
    @Binding var useFlyoverMap: Bool
    var dismiss: () -> Void
    @State var schoolName: String?
    @State var loadCancellable: Apollo.Cancellable?
    
    func reloadSchoolName(id: String) {
        loadCancellable?.cancel()
        loadCancellable = Network.shared.apollo.fetch(query: GetSchoolNameQuery(schoolID: id), cachePolicy: .returnCacheDataElseFetch) { result in
            if case .success(let result) = result, let name = result.data?.school?.name {
                schoolName = name
            }
        }
    }
    
    func reloadSchoolName() {
        if let id = schoolID {
            reloadSchoolName(id: id)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(schoolName ?? "School")) {
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
                
                Section(header: Text("Map")) {
                    let toggle = Toggle("Use 3D Satellite Map", isOn: $useFlyoverMap)
                    if #available(iOS 15.0, *) {
                        toggle.tint(Color.accentColor)
                    } else {
                        toggle
                    }
                }
                
                Section(header: Text("Advanced")) {
                    Text("School ID: \(schoolID ?? "None")").foregroundColor(.gray)
                    Button("Copy School ID") {
                        UIPasteboard.general.string = schoolID
                    }.disabled(schoolID == nil).foregroundColor(.primary)
                }
                
                Section(header: Text("About")) {
                    Link("YourBCABus Website", destination: URL(string: "https://yourbcabus.com")!).foregroundColor(.primary)
                    Link("YourBCABus Support", destination: URL(string: "https://about.yourbcabus.com/support")!).foregroundColor(.primary)
                    Link("YourBCABus Privacy Policy", destination: URL(string: "https://about.yourbcabus.com/support/privacy.html")!).foregroundColor(.primary)
                    Text("Version \((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?") (Build \((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "?"))").foregroundColor(.gray)
                }
            }.navigationBarTitle("Settings", displayMode: .inline).toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }.onAppear {
                reloadSchoolName()
            }.onChange(of: schoolID) { id in
                schoolName = nil
                if let id = id {
                    reloadSchoolName(id: id)
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
