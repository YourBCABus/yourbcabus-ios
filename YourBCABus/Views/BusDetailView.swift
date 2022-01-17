//
//  BusDetailView.swift
//  BusDetailView
//
//  Created by Anthony Li on 8/18/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import Apollo
import Combine

extension Array where Element == String {
    func toFormattedString() -> String {
        if #available(iOS 15.0, *) {
            return formatted()
        } else {
            return joined(separator: ", ")
        }
    }
}

struct BusDetailAttributeView: View {
    var title: LocalizedStringKey
    var content: Text
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).fontWeight(.bold).foregroundColor(.secondary).textCase(.uppercase)
            content.font(.title3).fontWeight(.medium)
        }.multilineTextAlignment(.leading)
    }
}

extension Result where Success == GraphQLResult<GetStopsQuery.Data> {
    var stops: [GetStopsQuery.Data.Bus.Stop] {
        if case .success(let result) = self {
            return result.data?.bus?.stops ?? []
        }
        return []
    }
}

struct BusDetailView: View {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var bus: BusModel
    var school: GetBusesQuery.Data.School?
    @Binding var starredIDs: Set<String>
    @Binding var selectedID: String?
    var schoolLocation: LocationModel?
    
    @State var result: Result<GraphQLResult<GetBusDetailsQuery.Data>, Error>?
    @State var stopsResult: Result<GraphQLResult<GetStopsQuery.Data>, Error>?
    @State var loadCancellables = [Apollo.Cancellable]()
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    
    let focusSubject = PassthroughSubject<LocationModel, Never>()
    
    var useFlyoverMap: Bool
    
    func loadDetails(id: String) {
        loadCancellables.forEach { $0.cancel() }
        loadCancellables = [
            Network.shared.apollo.watch(query: GetBusDetailsQuery(busID: id), cachePolicy: .returnCacheDataAndFetch) { result in
                self.result = result
            },
            Network.shared.apollo.watch(query: GetStopsQuery(busID: id), cachePolicy: .returnCacheDataAndFetch) { result in
                self.stopsResult = result
            }
        ]
    }
    
    func loadDetails() {
        loadDetails(id: bus.id)
    }
    
    func menuItems(for stop: StopModel) -> some View {
        Group {
            Button {
                focusSubject.send(stop.stopLocation!)
            } label: {
                Label("Show in Map", systemImage: "mappin.and.ellipse")
            }.disabled(stop.stopLocation == nil)
            
            Button {
                
            } label: {
                Label("Add Get Off Alert", systemImage: "bell.fill")
            }.disabled(true)
        }
    }
    
    var stopsList: AnyView {
        switch stopsResult {
        case .none:
            return AnyView(
                ProgressView("Loading").frame(maxWidth: .infinity)
            )
        case .some(.success(let result)):
            if let stops = result.data?.bus?.stops {
                if stops.isEmpty {
                    return AnyView(
                        Text("No stop data").fontWeight(.bold).foregroundColor(.secondary).textCase(.uppercase).padding(.horizontal)
                    )
                } else {
                    return AnyView(Group {
                        HStack {
                            Rectangle().fill(LinearGradient(colors: [Color.accentColor.opacity(0), Color.accentColor], startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1))).frame(width: 4).frame(width: 16)
                            // TODO: Better plural localization
                            Text(stops.count == 1 ? "1 stop" : "\(stops.count) stops").fontWeight(.bold).foregroundColor(.secondary).textCase(.uppercase)
                        }.frame(minHeight: 32).padding(.horizontal)
                        ForEach(Array(stops.sorted(with: { $0.order ?? .infinity }).enumerated()), id: \.1.id) { item in
                            let (index, stop) = item
                            HStack {
                                ZStack {
                                    if index + 1 >= stops.endIndex {
                                        GeometryReader { geometry in
                                            Rectangle().fill(Color.accentColor).frame(height: geometry.size.height / 2)
                                        }.frame(width: 4)
                                    } else {
                                        Rectangle().fill(Color.accentColor).frame(width: 4)
                                    }
                                    Circle().fill(Color.accentColor).frame(width: 16, height: 16)
                                }.frame(width: 16)
                                let stopContents = HStack {
                                    VStack(alignment: .leading) {
                                        Text(stop.name ?? "(unnamed stop)")
                                        if let description = stop.description {
                                            Text(description).font(.caption)
                                        }
                                    }
                                    Spacer()
                                    if let arrives = stop.arrives {
                                        Text("\(arrives, formatter: BusDetailView.timeFormatter)")
                                    }
                                }.multilineTextAlignment(.leading).foregroundColor(.primary)
                                
                                if let location = stop.stopLocation {
                                    Button {
                                        focusSubject.send(location)
                                    } label: {
                                        stopContents
                                    }
                                } else {
                                    stopContents
                                }
                                Menu {
                                    menuItems(for: stop)
                                } label: {
                                    Image(systemName: "ellipsis.circle.fill").accessibility(label: Text("Actions...")).padding(4)
                                }
                            }.frame(minHeight: 32).padding(.horizontal).background(Color(.systemBackground)).contextMenu {
                                menuItems(for: stop)
                            }
                        }
                    })
                }
            } else {
                return AnyView(
                    Text("Could not load stops").foregroundColor(.red).frame(maxWidth: .infinity)
                )
            }
        case .some(.failure(_)):
            return AnyView(
                Text("Could not load stops").foregroundColor(.red).frame(maxWidth: .infinity)
            )
        }
    }
    
    var body: some View {
        return VStack(spacing: 0) {
            switch result {
            case .none:
                ProgressView("Loading").frame(maxHeight: .infinity)
            case .some(.success(let result)):
                if let details = result.data?.bus {
                    if let school = school, let mappingData = school.mappingData {
                        Group {
                            if let stopsResult = stopsResult {
                                MapView(mappingData: mappingData, buses: school.buses, schoolLocation: schoolLocation, stops: stopsResult.stops, starredIDs: starredIDs, showScrim: true, selectedID: $selectedID, detailBusID: bus.id, focusSubject: focusSubject, useFlyoverMap: useFlyoverMap)
                            } else {
                                Rectangle().fill(Color.primary.opacity(0.1))
                            }
                        }.frame(height: verticalSizeClass == .compact ? 150 : 300)
                    }
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(bus.name ?? "(unnamed bus)").font(.largeTitle).fontWeight(.bold)
                                    Text(bus.status()).foregroundColor(.secondary)
                                }.multilineTextAlignment(.leading)
                                Spacer()
                                BoardingAreaView(bus.getBoardingArea()).font(.title).frame(height: 72)
                            }.padding(.all)
                            LazyVGrid(columns: [.init(.adaptive(minimum: 300))], alignment: .leading, spacing: 12) {
                                if let company = details.company {
                                    BusDetailAttributeView(title: "Operator", content: Text(company))
                                }
                                if !details.numbers.isEmpty {
                                    BusDetailAttributeView(title: "Bus No.", content: Text("\(details.numbers.toFormattedString())"))
                                }
                                if !details.phone.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Phone").font(.caption).fontWeight(.bold).foregroundColor(.secondary).textCase(.uppercase)
                                        VStack(alignment: .leading) {
                                            ForEach(details.phone, id: \.self) { phone in
                                                let url = URL(string: "telprompt://\(phone.filter { $0.isNumber })")
                                                Button {
                                                    UIApplication.shared.open(url!, options: [:]) { success in
                                                        if !success {
                                                            if let url = URL(string: "tel://\(phone.filter { $0.isNumber })") {
                                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                            }
                                                        }
                                                    }
                                                } label: {
                                                    Text(phone).font(.title3).fontWeight(.medium).multilineTextAlignment(.leading)
                                                }.disabled(url == nil)
                                            }
                                        }
                                    }
                                }
                                if !details.otherNames.isEmpty {
                                    BusDetailAttributeView(title: "Other Names", content: Text("\(details.otherNames.toFormattedString())"))
                                }
                            }.padding([.horizontal, .bottom])
                            stopsList
                        }
                    }
                } else {
                    Text("An error occurred.").foregroundColor(.red).frame(maxHeight: .infinity)
                }
            default:
                Text("An error occurred.").foregroundColor(.red).frame(maxHeight: .infinity)
            }
        }.navigationTitle(bus.name ?? "Bus").navigationBarTitleDisplayMode(.inline).toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if starredIDs.contains(bus.id) {
                    Button {
                        selectedID = "all.\(bus.id)"
                        starredIDs.remove(bus.id)
                    } label: {
                        Image(systemName: "star.fill").accessibility(label: Text("Starred"))
                    }
                } else {
                    Button {
                        starredIDs.insert(bus.id)
                    } label: {
                        Image(systemName: "star").accessibility(label: Text("Star"))
                    }
                }
            }
        }.onAppear {
            loadDetails()
        }.onChange(of: bus.id) { id in
            loadDetails(id: id)
        }
    }
}
