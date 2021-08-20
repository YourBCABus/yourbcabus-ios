//
//  App.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/2/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import YourBCABus_Embedded

@main
struct YourBCABus: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    static private let schoolDefaultsKey = "YBBSchoolID"
    
    @State var schoolID: String? = {
        if let id = UserDefaults.standard.string(forKey: schoolDefaultsKey) {
            return id
        } else if UserDefaults.standard.object(forKey: "starredBuses") != nil {
            UserDefaults.standard.set(Constants.schoolId, forKey: Self.schoolDefaultsKey)
            return Constants.schoolId
        } else {
            return nil
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView(schoolID: $schoolID)
        }.onChange(of: schoolID) { id in
            UserDefaults.standard.set(id, forKey: Self.schoolDefaultsKey)
        }
    }
}
