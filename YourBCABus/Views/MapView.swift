//
//  MapView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/12/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import MapKit

protocol LocationModel {
    var lat: Double { get }
    var long: Double { get }
}

extension GetBusesQuery.Data.School.MappingDatum.BoundingBoxA: Equatable, LocationModel {
    public static func == (lhs: GetBusesQuery.Data.School.MappingDatum.BoundingBoxA, rhs: GetBusesQuery.Data.School.MappingDatum.BoundingBoxA) -> Bool {
        lhs.lat == rhs.lat && lhs.long == rhs.long
    }
}
extension GetBusesQuery.Data.School.MappingDatum.BoundingBoxB: Equatable, LocationModel {
    public static func == (lhs: GetBusesQuery.Data.School.MappingDatum.BoundingBoxB, rhs: GetBusesQuery.Data.School.MappingDatum.BoundingBoxB) -> Bool {
        lhs.lat == rhs.lat && lhs.long == rhs.long
    }
}
extension GetBusesQuery.Data.School.MappingDatum.BoardingArea.Location: Equatable, LocationModel {
    public static func == (lhs: GetBusesQuery.Data.School.MappingDatum.BoardingArea.Location, rhs: GetBusesQuery.Data.School.MappingDatum.BoardingArea.Location) -> Bool {
        lhs.lat == rhs.lat && lhs.long == rhs.long
    }
}
extension GetBusesQuery.Data.School.MappingDatum.BoardingArea: Equatable {
    public static func == (lhs: GetBusesQuery.Data.School.MappingDatum.BoardingArea, rhs: GetBusesQuery.Data.School.MappingDatum.BoardingArea) -> Bool {
        lhs.name == rhs.name && lhs.location == rhs.location
    }
}
extension GetBusesQuery.Data.School.MappingDatum: Equatable {
    public static func == (lhs: GetBusesQuery.Data.School.MappingDatum, rhs: GetBusesQuery.Data.School.MappingDatum) -> Bool {
        lhs.boundingBoxA == rhs.boundingBoxA && lhs.boundingBoxB == rhs.boundingBoxB
    }
}
extension GetBusesQuery.Data.School.Bus: Identifiable {}

extension CLLocationCoordinate2D {
    init(_ location: LocationModel) {
        self.init(latitude: location.lat, longitude: location.long)
    }
}

struct MapView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    init(mappingData: GetBusesQuery.Data.School.MappingDatum, buses: [GetBusesQuery.Data.School.Bus] = [], starredIDs: Set<String> = [], showScrim: Bool = false, selectedID: Binding<String?>? = nil) {
        self.mappingData = mappingData
        self.buses = buses
        self.starredIDs = starredIDs
        self.showScrim = showScrim
        self.selectedID = selectedID
    }
    
    var mappingData: GetBusesQuery.Data.School.MappingDatum
    var buses: [GetBusesQuery.Data.School.Bus]
    var starredIDs: Set<String>
    var showScrim: Bool
    var selectedID: Binding<String?>?
    
    @State var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
    @State var highlightedID: String?
    
    func recomputeRegion(mappingData: GetBusesQuery.Data.School.MappingDatum) {
        region = MKCoordinateRegion(MKMapRect(a: MKMapPoint(CLLocationCoordinate2D(mappingData.boundingBoxA)), b: MKMapPoint(CLLocationCoordinate2D(mappingData.boundingBoxB))))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            let boardingAreas = [String: CLLocationCoordinate2D](mappingData.boardingAreas.map { ($0.name, CLLocationCoordinate2D($0.location)) }, uniquingKeysWith: { (_, last) in
                last
            })
            let now = Date()
            let annotations = buses.filter { bus in
                if let area = bus.getBoardingArea(at: now) {
                    return boardingAreas[area] != nil
                }
                return false
            }
            let baseColor = colorScheme == .dark ? Color.black : Color.white
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: annotations) { bus in
                MapAnnotation(coordinate: boardingAreas[bus.boardingArea!]!) {
                    ZStack {
                        Image(starredIDs.contains(bus.id) ? "Annotation - Bus Starred" : "Annotation - Bus").accessibility(label: Text(bus.name ?? "Bus")).frame(width: 44, height: 44).onTapGesture {
                            if highlightedID == bus.id {
                                highlightedID = nil
                            } else {
                                highlightedID = bus.id
                            }
                        }
                        if highlightedID == bus.id {
                            HStack {
                                Text(bus.name ?? "(unnamed bus)").foregroundColor(.primary)
                                if let area = bus.boardingArea {
                                    Text(area).fontWeight(.bold).foregroundColor(.primary)
                                }
                                if selectedID != nil {
                                    Button {
                                        selectedID?.wrappedValue = starredIDs.contains(bus.id) ? "starred.\(bus.id)" : "all.\(bus.id)"
                                    } label: {
                                        Image(systemName: "chevron.right.circle.fill").accessibility(label: Text("Details"))
                                    }
                                }
                            }.fixedSize(horizontal: true, vertical: false).padding(.horizontal).padding(.vertical, 8).background(baseColor.opacity(0.75)).cornerRadius(10).shadow(radius: 10).frame(height: 105, alignment: .top)
                        }
                    }.frame(width: 300, height: 200)
                }
            }.edgesIgnoringSafeArea(.all)
            if showScrim {
                Rectangle().fill(LinearGradient(colors: [baseColor.opacity(0.9), baseColor.opacity(0.6), baseColor.opacity(0)], startPoint: UnitPoint(x: 0, y: 0), endPoint: UnitPoint(x: 0, y: 1))).frame(maxWidth: .infinity).frame(height: 100).allowsHitTesting(false)
            }
        }.edgesIgnoringSafeArea(.all).onAppear {
            recomputeRegion(mappingData: mappingData)
        }.onChange(of: mappingData) { data in
            recomputeRegion(mappingData: data)
        }
    }
}

func fullScreenMap(mappingData: GetBusesQuery.Data.School.MappingDatum, buses: [GetBusesQuery.Data.School.Bus] = [], starredIDs: Set<String> = [], selectedID: Binding<String?>? = nil) -> some View {
    MapView(mappingData: mappingData, buses: buses, starredIDs: starredIDs, showScrim: true, selectedID: selectedID).navigationBarTitle("Map", displayMode: .inline)
}
