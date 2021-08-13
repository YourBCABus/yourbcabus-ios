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

struct ContentView: View {
    @Binding var schoolID: String?
    let endRefreshSubject = PassthroughSubject<Void, Never>()
    @State var settingsVisible = false
    @State var result: Result<GraphQLResult<GetBusesQuery.Data>, Error>?
    @State var loadCancellable: Apollo.Cancellable?
    @State var isStarred = Set<String>()
    @State var dismissedAlerts = Set<String>()
    @State var selectedID: String?
    
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
                            fullScreenMap(mappingData: mappingData, buses: result.data!.school!.buses, starredIDs: isStarred)
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
        }
    }
}
