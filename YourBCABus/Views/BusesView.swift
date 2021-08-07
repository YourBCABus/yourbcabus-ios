//
//  BusesView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import Apollo

struct BusesErrorView: View {
    var body: some View {
        Text("An error occurred.").foregroundColor(.red).padding()
    }
}

struct BusesView: View {
    var schoolID: String
    @State var result: Result<GraphQLResult<GetBusesQuery.Data>, Error>?
    @State var loadCancellable: Cancellable?
    
    func reloadData() {
        loadCancellable?.cancel()
        loadCancellable = Network.shared.apollo.fetch(query: GetBusesQuery(schoolID: schoolID)) { result in
            self.result = result
        }
    }
    
    var body: some View {
        SearchView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    #if !targetEnvironment(macCatalyst)
                    ReloadControl { end in
                        end()
                    }.frame(height: 1) // It's a hack but it works for iOS 14
                    #endif
                    switch result {
                    case .none:
                        ProgressView("Loading").padding(.vertical, 64)
                    case .some(.success(let result)):
                        if let school = result.data?.school {
                            ZStack(alignment: .bottom) {
                                Text("[pretend this is a map]").foregroundColor(.white).frame(height: 250)
                                HStack {
                                    Image(systemName: "map")
                                    Text(school.name ?? "Map").lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }.padding().frame(maxWidth: .infinity).background(Color.black.opacity(0.5)).foregroundColor(.white)
                            }.frame(maxWidth: .infinity).background(Color.blue).cornerRadius(16).padding([.horizontal, .bottom]).accessibility(label: Text("Map"))
                            ForEach(school.buses.sorted(by: { a, b in
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
                            }), id: \.id) { bus in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(bus.name ?? "(unnamed bus)").fontWeight(.bold).lineLimit(1)
                                        Text(bus.available ? "Not at BCA" : "Not running").foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle().fill(Color.blue)
                                        Text("?").foregroundColor(.white).fontWeight(.bold)
                                    }.aspectRatio(1, contentMode: .fit).frame(height: 48)
                                }.padding(.horizontal).padding(.vertical, 4)
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
            reloadData()
        }.onChange(of: schoolID) { _ in
            result = nil
            reloadData()
        }
    }
}
