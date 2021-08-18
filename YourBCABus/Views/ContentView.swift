//
//  ContentView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/2/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import Apollo
import Combine

let refreshInterval: TimeInterval = 15

extension UserDefaults {
    func readSet(_ key: String) -> Set<String> {
        if let array = array(forKey: key) as? [String] {
            return Set(array)
        } else {
            return []
        }
    }
    
    func writeSet(_ set: Set<String>, to key: String) {
        setValue([String](set), forKey: key)
    }
}

struct ContentView: View {
    @Binding var schoolID: String?
    let endRefreshSubject = PassthroughSubject<Void, Never>()
    @State var settingsVisible = false
    @State var result: Result<GraphQLResult<GetBusesQuery.Data>, Error>?
    @State var loadCancellable: Apollo.Cancellable?
    @State var isStarred = UserDefaults.standard.readSet("YBBStarredBusesSet")
    @State var dismissedAlerts = UserDefaults.standard.readSet("YBBDismissedAlertsSet")
    @State var selectedID: String?
    
    let refreshTimer = Timer.publish(every: refreshInterval, on: .main, in: .common).autoconnect()
    
    func reloadData(schoolID: String) {
        loadCancellable?.cancel()
        loadCancellable = Network.shared.apollo.fetch(query: GetBusesQuery(schoolID: schoolID), cachePolicy: .fetchIgnoringCacheData) { result in
            self.result = result
            endRefreshSubject.send()
        }
    }
    
    var content: AnyView {
        if let id = schoolID {
            return AnyView(NavigationView {
                BusesView(schoolID: id, onRefresh: {
                    reloadData(schoolID: id)
                }, endRefreshSubject: endRefreshSubject, result: $result, isStarred: $isStarred, dismissedAlerts: $dismissedAlerts, selectedID: $selectedID).edgesIgnoringSafeArea(.all).navigationTitle("YourBCABus").toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            settingsVisible = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
                Group {
                    if case let .success(result) = result {
                        if let mappingData = result.data?.school?.mappingData {
                            fullScreenMap(mappingData: mappingData, buses: result.data!.school!.buses, starredIDs: isStarred, selectedID: $selectedID)
                        } else {
                            Text("No Bus Selected").foregroundColor(.secondary)
                        }
                    }
                }
            })
        } else {
            return AnyView(EmptyView())
        }
    }
    
    var body: some View {
        content.sheet(isPresented: .constant(schoolID == nil)) {
            if #available(iOS 15.0, *) {
                OnboardingView(schoolID: $schoolID).interactiveDismissDisabled()
            } else {
                OnboardingView(schoolID: $schoolID).undismissable()
            }
        }.sheet(isPresented: $settingsVisible) {
            SettingsView(schoolID: $schoolID) {
                settingsVisible = false
            }
        }.onAppear {
            if let id = schoolID {
                reloadData(schoolID: id)
            }
        }.onChange(of: schoolID) { id in
            result = nil
            selectedID = nil
            if let id = id {
                reloadData(schoolID: id)
            }
        }.onReceive(refreshTimer) { _ in
            if let id = schoolID, UIApplication.shared.applicationState == .active {
                reloadData(schoolID: id)
            }
        }.onChange(of: isStarred) { starred in
            UserDefaults.standard.writeSet(starred, to: "YBBStarredBusesSet")
        }.onChange(of: dismissedAlerts) { dismissedAlerts in
            UserDefaults.standard.writeSet(dismissedAlerts, to: "YBBDismissedAlertsSet")
        }.onChange(of: selectedID) { id in
            print("ID changing to \(id ?? "none")")
        }
    }
}
