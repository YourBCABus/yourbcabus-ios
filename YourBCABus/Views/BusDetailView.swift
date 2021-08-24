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

struct BusDetailView: View {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var bus: BusModel
    var school: GetBusesQuery.Data.School?
    var starredIDs: Set<String>?
    var selectedID: Binding<String?>?
    var schoolLocation: LocationModel?
    
    @State var result: Result<GraphQLResult<GetBusDetailsQuery.Data>, Error>?
    @State var loadCancellable: Apollo.Cancellable?
    
    let focusSubject = PassthroughSubject<LocationModel, Never>()
    
    var useFlyoverMap: Bool
    
    func loadDetails(id: String) {
        loadCancellable?.cancel()
        loadCancellable = Network.shared.apollo.fetch(query: GetBusDetailsQuery(busID: id), cachePolicy: .fetchIgnoringCacheData) { result in
            self.result = result
        }
    }
    
    func loadDetails() {
        loadDetails(id: bus.id)
    }
    
    var body: some View {
        return VStack(spacing: 0) {
            switch result {
            case .none:
                ProgressView("Loading").frame(maxHeight: .infinity)
            case .some(.success(let result)):
                if let details = result.data?.bus {
                    if let school = school, let mappingData = school.mappingData {
                        MapView(mappingData: mappingData, buses: school.buses, schoolLocation: schoolLocation, stops: details.stops, starredIDs: starredIDs ?? [], showScrim: true, selectedID: selectedID, detailBusID: bus.id, focusSubject: focusSubject, useFlyoverMap: useFlyoverMap).edgesIgnoringSafeArea(.all).frame(height: 200)
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
                            LazyVGrid(columns: Array(repeating: .init(.adaptive(minimum: 150)), count: 3), alignment: .leading, spacing: 12) {
                                if let company = details.company {
                                    BusDetailAttributeView(title: "Operator", content: Text(company))
                                }
                                if !details.numbers.isEmpty {
                                    BusDetailAttributeView(title: "Bus No.", content: Text("\(details.numbers.toFormattedString())"))
                                }
                                if !details.phone.isEmpty {
                                    BusDetailAttributeView(title: "Phone", content: Text("\(details.phone.toFormattedString())"))
                                }
                                if !details.otherNames.isEmpty {
                                    BusDetailAttributeView(title: "Other Names", content: Text("\(details.otherNames.toFormattedString())"))
                                }
                            }.padding(.horizontal)
                            if details.stops.isEmpty {
                                Text("No stop data").fontWeight(.bold).foregroundColor(.secondary).textCase(.uppercase).padding(.horizontal)
                            } else {
                                HStack {
                                    Rectangle().fill(LinearGradient(colors: [Color.accentColor.opacity(0), Color.accentColor], startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1))).frame(width: 4).frame(width: 16)
                                    // TODO: Better plural localization
                                    Text(details.stops.count == 1 ? "1 stop" : "\(details.stops.count) stops").fontWeight(.bold).foregroundColor(.secondary).textCase(.uppercase)
                                }.frame(minHeight: 32).padding(.horizontal)
                                ForEach(Array(details.stops.sorted(with: { $0.order ?? .infinity }).enumerated()), id: \.1.id) { item in
                                    let (index, stop) = item
                                    HStack {
                                        ZStack {
                                            if index + 1 >= details.stops.endIndex {
                                                GeometryReader { geometry in
                                                    Rectangle().fill(Color.accentColor).frame(height: geometry.size.height / 2)
                                                }.frame(width: 4)
                                            } else {
                                                Rectangle().fill(Color.accentColor).frame(width: 4)
                                            }
                                            Circle().fill(Color.accentColor).frame(width: 16, height: 16)
                                        }.frame(width: 16)
                                        let stopContents = VStack(alignment: .leading) {
                                            HStack(alignment: .top) {
                                                Text(stop.name ?? "(unnamed stop)")
                                                Spacer()
                                                if let arrives = stop.arrives {
                                                    Text("\(arrives, formatter: BusDetailView.timeFormatter)")
                                                }
                                            }
                                            if let description = stop.description {
                                                Text(description).font(.caption)
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
                                    }.frame(minHeight: 32).padding(.horizontal)
                                }
                            }
                        }
                    }
                } else {
                    Text("An error occurred.").foregroundColor(.red).frame(maxHeight: .infinity)
                }
            default:
                Text("An error occurred.").foregroundColor(.red).frame(maxHeight: .infinity)
            }
        }.navigationTitle(bus.name ?? "Bus").navigationBarTitleDisplayMode(.inline).onAppear {
            loadDetails()
        }.onChange(of: bus.id) { id in
            loadDetails(id: id)
        }
    }
}
