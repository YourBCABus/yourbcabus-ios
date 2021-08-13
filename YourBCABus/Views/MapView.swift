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
extension GetBusesQuery.Data.School.MappingDatum: Equatable {
    public static func == (lhs: GetBusesQuery.Data.School.MappingDatum, rhs: GetBusesQuery.Data.School.MappingDatum) -> Bool {
        lhs.boundingBoxA == rhs.boundingBoxA && lhs.boundingBoxB == rhs.boundingBoxB
    }
}

extension CLLocationCoordinate2D {
    init(_ location: LocationModel) {
        self.init(latitude: location.lat, longitude: location.long)
    }
}

struct MapView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    init(mappingData: GetBusesQuery.Data.School.MappingDatum, showScrim: Bool = false) {
        self.mappingData = mappingData
        self.showScrim = showScrim
    }
    
    var mappingData: GetBusesQuery.Data.School.MappingDatum
    var showScrim: Bool
    
    @State var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
    
    func recomputeRegion(mappingData: GetBusesQuery.Data.School.MappingDatum) {
        region = MKCoordinateRegion(MKMapRect(a: MKMapPoint(CLLocationCoordinate2D(mappingData.boundingBoxA)), b: MKMapPoint(CLLocationCoordinate2D(mappingData.boundingBoxB))))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, showsUserLocation: true).edgesIgnoringSafeArea(.all)
            if showScrim {
                let baseColor = colorScheme == .dark ? Color.black : Color.white
                Rectangle().fill(LinearGradient(colors: [baseColor.opacity(0.9), baseColor.opacity(0)], startPoint: UnitPoint(x: 0, y: 0), endPoint: UnitPoint(x: 0, y: 1))).frame(maxWidth: .infinity).frame(height: 100).allowsHitTesting(false)
            }
        }.edgesIgnoringSafeArea(.all).onAppear {
            recomputeRegion(mappingData: mappingData)
        }.onChange(of: mappingData) { data in
            recomputeRegion(mappingData: data)
        }
    }
}

func fullScreenMap(mappingData: GetBusesQuery.Data.School.MappingDatum) -> some View {
    MapView(mappingData: mappingData, showScrim: true).navigationBarTitle("Map", displayMode: .inline)
}
