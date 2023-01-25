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

func isoStringToDate(_ str: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: str)
}

struct BusRowView: View {
    var uiID: String
    var bus: GetBusesQuery.Data.School.Bus
    @Binding var isStarred: Bool
    @Binding var selectedID: String?
    
    var linkContent: some View {
        ZStack {
            Rectangle().fill(Color.accentColor.opacity(0.3)).cornerRadius(8).padding(.horizontal, 8).animation(nil).opacity(selectedID == uiID ? 1 : 0).animation(.linear)
            HStack {
                let boardingArea = bus.getBoardingArea()
                VStack(alignment: .leading) {
                    Text(bus.name ?? "(unnamed bus)").fontWeight(.bold).lineLimit(1).foregroundColor(.primary)
                    Text(bus.status()).foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    isStarred.toggle()
                } label: {
                    Image(systemName: isStarred ? "star.fill" : "star").foregroundColor(isStarred ? .blue : .secondary)
                }.accessibility(label: Text(isStarred ? "Unstar" : "Star"))
                BoardingAreaView(boardingArea).frame(height: 48)
                // TODO: Does this work with RTL?
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary).padding(.trailing, 3)
            }.padding(.horizontal).padding(.vertical, 4).accessibility(addTraits: selectedID == uiID ? .isSelected : [])
        }
    }
    
    var body: some View {
        Button {
            selectedID = uiID
        } label: {
            linkContent.background(Color(.systemBackground)).contextMenu {
                if isStarred {
                    Button {
                        isStarred = false
                    } label: {
                        Label("Unstar", systemImage: "star.slash.fill")
                    }
                } else {
                    Button {
                        isStarred = true
                    } label: {
                        Label("Star", systemImage: "star.fill")
                    }
                }
            }
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
    var onRefresh: () async -> Void
    @Binding var result: Result<GraphQLResult<GetBusesQuery.Data>, Error>?
    @Binding var isStarred: Set<String>
    @Binding var dismissedAlerts: Set<String>
    @Binding var selectedID: String?
    var useFlyoverMap: Bool
    
    var body: some View {
        let now = Date()
        return SearchView {
            ScrollView {
                VStack(spacing: 0) {
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
                        }), let starredBuses = buses.filter { isStarred.contains($0.id) }, let alerts = school.alerts.filter { alert in
                            if dismissedAlerts.contains(alert.id) {
                                return false
                            }
                            if let end = isoStringToDate(alert.end) {
                                if end >= now {
                                    if let start = isoStringToDate(alert.start) {
                                        return start <= now
                                    } else {
                                        return true
                                    }
                                } else {
                                    return false
                                }
                            } else {
                                return true
                            }
                        } {
                            ForEach(alerts, id: \.id) { alert in
                                Button {
                                    selectedID = alert.id
                                } label: {
                                    AlertView(alert: alert, isActive: selectedID == alert.id) {
                                        dismissedAlerts.insert(alert.id)
                                    }
                                }.padding(.horizontal).padding(.bottom, 8)
                            }
                            if let mappingData = school.mappingData {
                                ZStack(alignment: .bottom) {
                                    MapView(mappingData: mappingData, buses: buses, starredIDs: isStarred, selectedID: $selectedID, useFlyoverMap: useFlyoverMap).frame(height: 250)
                                    Button {
                                        selectedID = "map"
                                    } label: {
                                        HStack {
                                            Image(systemName: "map")
                                            Text(school.name ?? "Map").lineLimit(1)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }.padding().frame(maxWidth: .infinity).background(Color.black.opacity(0.6)).foregroundColor(.white)
                                    }
                                }.frame(maxWidth: .infinity).background(Color.blue).cornerRadius(16).padding([.horizontal, .bottom]).accessibility(label: Text("Map"))
                            }
                            LazyVStack(spacing: 0) {
                                if !starredBuses.isEmpty {
                                    BusesSectionHeader(text: "Starred")
                                }
                                ForEach(starredBuses.map { ($0, "starred.\($0.id)") }, id: \.1) { tuple in
                                    let (bus, uiID) = tuple
                                    BusRowView(uiID: uiID, bus: bus, isStarred: Binding {
                                        isStarred.contains(bus.id)
                                    } set: { starred in
                                        if starred {
                                            isStarred.insert(bus.id)
                                        } else {
                                            isStarred.remove(bus.id)
                                        }
                                    }, selectedID: $selectedID)
                                }
                                if !starredBuses.isEmpty {
                                    BusesSectionHeader(text: "All")
                                }
                                ForEach(buses.map { ($0, "all.\($0.id)") }, id: \.1) { tuple in
                                    let (bus, uiID) = tuple
                                    BusRowView(uiID: uiID, bus: bus, isStarred: Binding {
                                        isStarred.contains(bus.id)
                                    } set: { starred in
                                        if starred {
                                            isStarred.insert(bus.id)
                                        } else {
                                            isStarred.remove(bus.id)
                                        }
                                    }, selectedID: $selectedID)
                                }
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
            #if !targetEnvironment(macCatalyst)
            .refreshable {
                await onRefresh()
            }
            #endif
        } searchResultsContent: { text -> AnyView in
            if text.isEmpty {
                return AnyView(EmptyView())
            } else {
                switch result {
                case .some(.success(let result)):
                    let predicate = busPredicate(for: text)
                    if let buses = result.data?.school?.buses.filter({ predicate.evaluate(with: $0) }).sorted(by: { a, b in
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
                    }) {
                        return AnyView(ScrollView {
                            LazyVStack {
                                ForEach(buses.map { ($0, isStarred.contains($0.id) ? "starred.\($0.id)" : "all.\($0.id)") }, id: \.1) { tuple in
                                    let (bus, uiID) = tuple
                                    BusRowView(uiID: uiID, bus: bus, isStarred: Binding {
                                        isStarred.contains(bus.id)
                                    } set: { starred in
                                        if starred {
                                            isStarred.insert(bus.id)
                                        } else {
                                            isStarred.remove(bus.id)
                                        }
                                    }, selectedID: $selectedID)
                                }
                            }
                        }.accentColor(Color("Primary")))
                    } else {
                        return AnyView(EmptyView())
                    }
                default:
                    return AnyView(EmptyView())
                }
            }
        }.edgesIgnoringSafeArea(.all)
    }
}
