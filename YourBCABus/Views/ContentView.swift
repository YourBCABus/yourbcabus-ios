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
import FirebaseMessaging
import YourBCABus_Core

let refreshInterval: TimeInterval = 15

extension GetBusesQuery.Data.School.Location: LocationModel {}

extension UserDefaults {
    func readSet(_ key: String) -> Set<String> {
        if let array = array(forKey: key) as? [String] {
            return Set(array)
        } else {
            return []
        }
    }
    
    func writeSet(_ set: Set<String>, to key: String) {
        setValue([String](set), forKey: key)
    }
}

func migrateOldStarredBuses() -> Set<String> {
    var result = Set<String>()
    if let dict = UserDefaults.standard.dictionary(forKey: "starredBuses") as? [String: Bool] {
        result.formUnion(dict.filter { $0.value }.keys)
        UserDefaults.standard.removeObject(forKey: "starredBuses")
    }
    if let suite = UserDefaults(suiteName: Constants.groupId), let data = suite.data(forKey: Constants.currentDestinationDefaultsKey), let route = try? PropertyListDecoder().decode(Route.self, from: data), let busID = route.bus?._id {
        result.insert(busID)
        suite.removeObject(forKey: Constants.currentDestinationDefaultsKey)
    }
    result.forEach { id in
        // TODO: Better place to put this?
        Messaging.messaging().unsubscribe(fromTopic: "school.\(Constants.schoolId).bus.\(id)")
    }
    if !result.isEmpty {
        // TODO: Definitely better place to put this
        if UserDefaults.standard.bool(forKey: AppDelegate.busArrivalNotificationsDefaultKey) {
            result.forEach { id in
                Messaging.messaging().subscribe(toTopic: "bus.\(id)")
            }
        }
        
        Messaging.messaging().unsubscribe(fromTopic: "school.\(Constants.schoolId).dismissal.banner")
        UserDefaults.standard.writeSet(result, to: "YBBStarredBusesSet")
    }
    return result
}

func migrateOldDismissedAlerts() -> Set<String> {
    if let dict = UserDefaults.standard.dictionary(forKey: "dismissedAlerts") {
        UserDefaults.standard.set([String: Any](), forKey: "dismissedAlerts")
        let set = Set(dict.keys)
        UserDefaults.standard.writeSet(set, to: "YBBDismissedAlertsSet")
        return set
    } else {
        return []
    }
}

struct ContentView: View {
    @Binding var schoolID: String?
    let endRefreshSubject = PassthroughSubject<Void, Never>()
    @State var settingsVisible = false
    @State var notificationPromptVisible = false
    @State var result: Result<GraphQLResult<GetBusesQuery.Data>, Error>?
    @State var loadCancellable: Apollo.Cancellable?
    @State var isStarred = UserDefaults.standard.readSet("YBBStarredBusesSet").union(migrateOldStarredBuses())
    @State var dismissedAlerts = UserDefaults.standard.readSet("YBBDismissedAlertsSet").union(migrateOldDismissedAlerts())
    @State var useFlyoverMap = UserDefaults.standard.bool(forKey: MapViewController.useFlyoverMapDefaultsKey)
    @State var selectedID: String?
    @EnvironmentObject var appDelegate: AppDelegate
    
    @State var busArrivalNotifications = UserDefaults.standard.bool(forKey: AppDelegate.busArrivalNotificationsDefaultKey)
    
    let refreshTimer = Timer.publish(every: refreshInterval, on: .main, in: .common).autoconnect()
    
    func reloadData(schoolID: String) {
        loadCancellable?.cancel()
        loadCancellable = Network.shared.apollo.fetch(query: GetBusesQuery(schoolID: schoolID), cachePolicy: .fetchIgnoringCacheData) { result in
            self.result = result
            endRefreshSubject.send()
        }
    }
    
    var links: some View {
        Group {
            switch result {
            case .some(.success(let result)):
                if let school = result.data?.school {
                    let buses = school.buses
                    let alerts = school.alerts
                    let starredBuses = buses.filter { isStarred.contains($0.id) }
                    ForEach(alerts, id: \.id) { alert in
                        NavigationLink(destination: AlertDetailView(alertID: alert.id).navigationTitle(Text(alert.title)).navigationBarTitleDisplayMode(.inline), tag: alert.id, selection: $selectedID) {
                            EmptyView()
                        }
                    }
                    if let mappingData = school.mappingData {
                        NavigationLink(destination: fullScreenMap(mappingData: mappingData, buses: buses, starredIDs: isStarred, selectedID: $selectedID, useFlyoverMap: useFlyoverMap), tag: "map", selection: $selectedID) {
                            EmptyView()
                        }
                    }
                    ForEach(starredBuses.map { ($0, "starred.\($0.id)") }, id: \.1) { tuple in
                        let (bus, uiID) = tuple
                        NavigationLink(destination: BusDetailView(bus: bus, school: school, starredIDs: $isStarred, selectedID: $selectedID, schoolLocation: school.location, useFlyoverMap: useFlyoverMap), tag: uiID, selection: $selectedID) {
                            EmptyView()
                        }
                    }
                    ForEach(buses.map { ($0, "all.\($0.id)") }, id: \.1) { tuple in
                        let (bus, uiID) = tuple
                        NavigationLink(destination: BusDetailView(bus: bus, school: school, starredIDs: $isStarred, selectedID: $selectedID, schoolLocation: school.location, useFlyoverMap: useFlyoverMap), tag: uiID, selection: $selectedID) {
                            EmptyView()
                        }
                    }
                } else {
                    EmptyView()
                }
            default:
                EmptyView()
            }
        }
    }
    
    var content: AnyView {
        if let id = schoolID {
            return AnyView(Group {
                NavigationView {
                    Group {
                        BusesView(schoolID: id, onRefresh: {
                            reloadData(schoolID: id)
                            var bag = Set<AnyCancellable>()
                            await withCheckedContinuation { continuation in
                                endRefreshSubject.sink(receiveCompletion: { _ in }, receiveValue: { _ in
                                    continuation.resume()
                                }).store(in: &bag)
                            }
                            try? await Task.sleep(nanoseconds: 500_000_000)
                        }, result: $result, isStarred: $isStarred, dismissedAlerts: $dismissedAlerts, selectedID: $selectedID, useFlyoverMap: useFlyoverMap).navigationTitle("YourBCABus").toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    settingsVisible = true
                                } label: {
                                    Label("Settings", systemImage: "gear")
                                }
                            }
                        }
                        links
                    }
                    Group {
                        if case let .success(result) = result {
                            if let mappingData = result.data?.school?.mappingData {
                                fullScreenMap(mappingData: mappingData, buses: result.data!.school!.buses, starredIDs: isStarred, selectedID: $selectedID)
                            } else {
                                Text("No Bus Selected").foregroundColor(.secondary)
                            }
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
            OnboardingView(schoolID: $schoolID).interactiveDismissDisabled()
        }.sheet(isPresented: $settingsVisible) {
            SettingsView(schoolID: $schoolID, busArrivalNotifications: $busArrivalNotifications, useFlyoverMap: $useFlyoverMap) {
                settingsVisible = false
            }
        }.sheet(isPresented: $notificationPromptVisible) {
            NotificationPromptView(isVisible: $notificationPromptVisible, busArrivalNotifications: $busArrivalNotifications)
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
        }.onReceive(refreshTimer) { _ in
            if let id = schoolID, UIApplication.shared.applicationState == .active {
                reloadData(schoolID: id)
            }
        }.onChange(of: isStarred) { [isStarred] starred in
            if busArrivalNotifications {
                appDelegate.subscribe(busIDs: starred.subtracting(isStarred))
                appDelegate.unsubscribe(busIDs: isStarred.subtracting(starred))
            } else if starred.count > isStarred.count && !UserDefaults.standard.bool(forKey: "didAskToSetUpBusArrivalNotifications") {
                UserDefaults.standard.set(true, forKey: "didAskToSetUpBusArrivalNotifications")
                notificationPromptVisible = true
            }
            UserDefaults.standard.writeSet(starred, to: "YBBStarredBusesSet")
        }.onChange(of: dismissedAlerts) { dismissedAlerts in
            UserDefaults.standard.writeSet(dismissedAlerts, to: "YBBDismissedAlertsSet")
        }.onChange(of: busArrivalNotifications) { [busArrivalNotifications] newValue in
            if busArrivalNotifications != newValue {
                UserDefaults.standard.set(newValue, forKey: AppDelegate.busArrivalNotificationsDefaultKey)
                if newValue {
                    appDelegate.subscribe(busIDs: isStarred)
                } else {
                    appDelegate.unsubscribe(busIDs: isStarred)
                }
            }
        }.onChange(of: useFlyoverMap) { [useFlyoverMap] newValue in
            if useFlyoverMap != newValue {
                UserDefaults.standard.set(newValue, forKey: MapViewController.useFlyoverMapDefaultsKey)
            }
        }
    }
}
