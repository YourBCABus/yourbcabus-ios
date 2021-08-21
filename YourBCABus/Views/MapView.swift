//
//  MapView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/12/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import MapKit
import Combine

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
    
    init(mappingData: GetBusesQuery.Data.School.MappingDatum, buses: [GetBusesQuery.Data.School.Bus] = [], schoolLocation: LocationModel? = nil, stops: [StopModel] = [], starredIDs: Set<String> = [], showScrim: Bool = false, selectedID: Binding<String?>? = nil, detailBusID: String? = nil, focusSubject: PassthroughSubject<LocationModel, Never>? = nil) {
        self.mappingData = mappingData
        self.buses = buses
        self.schoolLocation = schoolLocation
        self.stops = stops
        self.starredIDs = starredIDs
        self.showScrim = showScrim
        self.selectedID = selectedID
        self.detailBusID = detailBusID
        self.focusSubject = focusSubject
    }
    
    var mappingData: GetBusesQuery.Data.School.MappingDatum
    var buses: [GetBusesQuery.Data.School.Bus]
    var schoolLocation: LocationModel?
    var stops: [StopModel]
    var starredIDs: Set<String>
    var showScrim: Bool
    var selectedID: Binding<String?>?
    var detailBusID: String?
    let focusSubject: PassthroughSubject<LocationModel, Never>?
        
    var body: some View {
        ZStack(alignment: .top) {
            let baseColor = colorScheme == .dark ? Color.black : Color.white
            MapInternalView(mappingData: mappingData, buses: buses, schoolLocation: schoolLocation, stops: stops, starredIDs: starredIDs, selectedID: selectedID, detailBusID: detailBusID, focusSubject: focusSubject).edgesIgnoringSafeArea(.all)
            if showScrim {
                Rectangle().fill(LinearGradient(colors: [baseColor.opacity(0.9), baseColor.opacity(0.9), baseColor.opacity(0.6), baseColor.opacity(0)], startPoint: UnitPoint(x: 0, y: 0), endPoint: UnitPoint(x: 0, y: 1))).frame(maxWidth: .infinity).frame(height: 110).allowsHitTesting(false)
            }
        }.edgesIgnoringSafeArea(.all)
    }
}

struct MapInternalView: UIViewControllerRepresentable {
    var mappingData: GetBusesQuery.Data.School.MappingDatum
    var buses: [GetBusesQuery.Data.School.Bus]
    var schoolLocation: LocationModel?
    var stops: [StopModel]
    var starredIDs: Set<String>
    var selectedID: Binding<String?>?
    var detailBusID: String?
    let focusSubject: PassthroughSubject<LocationModel, Never>?
    
    func makeUIViewController(context: Context) -> MapViewController {
        let controller = MapViewController()
        controller.view = MKMapView()
        controller.setupView()
        updateUIViewController(controller, context: context)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        let reframe = uiViewController.mappingData != mappingData
        uiViewController.delegate = context.coordinator
        uiViewController.mappingData = mappingData
        uiViewController.buses = buses
        uiViewController.schoolLocation = schoolLocation.map { CLLocationCoordinate2D($0) }
        uiViewController.stops = stops
        uiViewController.reloadsMapTypeOnRegionChange = !stops.isEmpty
        uiViewController.isStarred = starredIDs
        uiViewController.detailBus = detailBusID
        context.coordinator.cancellables = []
        focusSubject?.sink { location in
            uiViewController.focus(on: CLLocationCoordinate2D(location))
        }.store(in: &context.coordinator.cancellables)
        if reframe {
            uiViewController.reframeMap()
        }
        uiViewController.reloadBuses()
        uiViewController.reloadStops()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: MapViewControllerDelegate {
        let parent: MapInternalView
        var cancellables = Set<AnyCancellable>()
        
        init(_ parent: MapInternalView) {
            self.parent = parent
        }
        
        func busSelected(id: String) {
            parent.selectedID?.wrappedValue = parent.starredIDs.contains(id) ? "starred.\(id)" : "all.\(id)"
        }
    }
}

func fullScreenMap(mappingData: GetBusesQuery.Data.School.MappingDatum, buses: [GetBusesQuery.Data.School.Bus] = [], starredIDs: Set<String> = [], selectedID: Binding<String?>? = nil) -> some View {
    MapView(mappingData: mappingData, buses: buses, starredIDs: starredIDs, showScrim: true, selectedID: selectedID).navigationBarTitle("Map", displayMode: .inline)
}
