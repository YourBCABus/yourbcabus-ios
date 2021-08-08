//
//  BusesView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import Apollo
import Combine

struct BusRowView: View {
    var uiID: String
    var bus: GetBusesQuery.Data.School.Bus
    @Binding var isStarred: Bool
    @Binding var selectedID: String?
    
    var linkContent: some View {
        ZStack(alignment: .trailing) {
            HStack {
                VStack(alignment: .leading) {
                    Text(bus.name ?? "(unnamed bus)").fontWeight(.bold).lineLimit(1).foregroundColor(.primary)
                    Text(bus.available ? "Not at BCA" : "Not running").foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    withAnimation {
                        isStarred.toggle()
                    }
                } label: {
                    Image(systemName: isStarred ? "star.fill" : "star").foregroundColor(isStarred ? .blue : .secondary)
                }.accessibility(label: Text(isStarred ? "Unstar" : "Star"))
                ZStack {
                    Circle().fill(Color.blue)
                    Text("?").foregroundColor(.white).fontWeight(.bold)
                }.aspectRatio(1, contentMode: .fit).frame(height: 48)
            }.padding(.horizontal)
            // TODO: Does this work with RTL?
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary).padding(.trailing, 3)
        }.padding(.vertical, 4)
    }
    
    var destination: some View {
        Text(bus.name ?? "(unnamed bus)").navigationTitle(bus.name ?? "(unnamed bus)")
    }
    
    var body: some View {
        // Technically this is deprecated on iOS 15 but the new one causes a crash, so we're kinda stuck here
        NavigationLink(destination: destination, tag: uiID, selection: $selectedID) {
            linkContent
        }
    }
}

struct BusesErrorView: View {
    var body: some View {
        Text("An error occurred.").foregroundColor(.red).padding()
    }
}

struct BusesSectionHeader: View {
    var text: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            Text(text).fontWeight(.bold).font(.callout).textCase(.uppercase).multilineTextAlignment(.leading)
        }.padding(.horizontal).padding(.bottom, 8).padding(.top, 16).foregroundColor(.secondary).frame(maxWidth: .infinity)
    }
}

struct BusesView: View {
    var schoolID: String
    let endRefreshSubject = PassthroughSubject<Void, Never>()
    @State var result: Result<GraphQLResult<GetBusesQuery.Data>, Error>?
    @State var loadCancellable: Apollo.Cancellable?
    @State var isStarred = [String: Bool]()
    @State var selectedID: String?
    
    func reloadData(schoolID: String) {
        loadCancellable?.cancel()
        loadCancellable = Network.shared.apollo.fetch(query: GetBusesQuery(schoolID: schoolID)) { result in
            self.result = result
            endRefreshSubject.send()
        }
    }
    
    var body: some View {
        SearchView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    #if !targetEnvironment(macCatalyst)
                    ReloadControl(endRefreshSubject: endRefreshSubject) {
                        reloadData(schoolID: schoolID)
                    }.frame(height: 1) // It's a hack but it works for iOS 14
                    #endif
                    switch result {
                    case .none:
                        ProgressView("Loading").padding(.vertical, 64)
                    case .some(.success(let result)):
                        if let school = result.data?.school, let buses = school.buses.sorted(by: { a, b in
                            if a.available && !b.available {
                                return true
                            } else if !a.available && b.available {
                                return false
                            }
                            
                            if let aName = a.name, let bName = b.name {
                                return aName < bName
                            } else if a.name != nil && b.name == nil {
                                return true
                            } else if a.name == nil && b.name != nil {
                                return false
                            } else {
                                return a.id < b.id
                            }
                        }), let starredBuses = buses.filter { isStarred[$0.id] ?? false } {
                            ZStack(alignment: .bottom) {
                                Text("[pretend this is a map]").foregroundColor(.white).frame(height: 250)
                                HStack {
                                    Image(systemName: "map")
                                    Text(school.name ?? "Map").lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }.padding().frame(maxWidth: .infinity).background(Color.black.opacity(0.5)).foregroundColor(.white)
                            }.frame(maxWidth: .infinity).background(Color.blue).cornerRadius(16).padding([.horizontal, .bottom]).accessibility(label: Text("Map"))
                            if !starredBuses.isEmpty {
                                BusesSectionHeader(text: "Starred")
                            }
                            ForEach(starredBuses.map { ($0, "starred.\($0.id)") }, id: \.1) { tuple in
                                let (bus, uiID) = tuple
                                BusRowView(uiID: uiID, bus: bus, isStarred: Binding {
                                    isStarred[bus.id] ?? false
                                } set: { starred in
                                    isStarred[bus.id] = starred ? true : nil
                                }, selectedID: $selectedID)
                            }
                            if !starredBuses.isEmpty {
                                BusesSectionHeader(text: "All")
                            }
                            ForEach(buses.map { ($0, "all.\($0.id)") }, id: \.1) { tuple in
                                let (bus, uiID) = tuple
                                BusRowView(uiID: uiID, bus: bus, isStarred: Binding {
                                    isStarred[bus.id] ?? false
                                } set: { starred in
                                    isStarred[bus.id] = starred ? true : nil
                                }, selectedID: $selectedID)
                            }
                        } else {
                            BusesErrorView()
                        }
                    case .some(.failure(_)):
                        BusesErrorView()
                    }
                    FooterView().padding()
                }.listStyle(PlainListStyle())
            }
        } searchResultsContent: { text -> AnyView in
            if text.isEmpty {
                return AnyView(EmptyView())
            } else {
                return AnyView(Text("Coming soon"))
            }
        }.edgesIgnoringSafeArea(.all).onAppear {
            reloadData(schoolID: schoolID)
        }.onChange(of: schoolID) { id in
            result = nil
            isStarred = [:]
            selectedID = nil
            reloadData(schoolID: id)
        }
    }
}
