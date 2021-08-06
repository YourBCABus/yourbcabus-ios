//
//  BusesView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct BusesView: View {
    var schoolID: String
    
    var body: some View {
        SearchView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    #if !targetEnvironment(macCatalyst)
                    ReloadControl { end in
                        end()
                    }.frame(height: 0)
                    #endif
                    ZStack(alignment: .bottom) {
                        Text("[pretend this is a map]").foregroundColor(.white).frame(height: 250)
                        HStack {
                            Image(systemName: "map")
                            Text(schoolID).lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }.padding().frame(maxWidth: .infinity).background(Color.black.opacity(0.5)).foregroundColor(.white)
                    }.frame(maxWidth: .infinity).background(Color.blue).cornerRadius(16).padding().accessibility(label: Text("Map"))
                    ForEach(1..<100) { i in
                        HStack {
                            Text("Bus \(i)")
                            Spacer()
                            ZStack {
                                Circle().fill(Color.blue)
                                Text("\(i)").foregroundColor(.white).fontWeight(.bold)
                            }.aspectRatio(1, contentMode: .fit).frame(height: 48)
                        }.padding(.horizontal).padding(.vertical, 4)
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
        }.edgesIgnoringSafeArea(.all)
    }
}
