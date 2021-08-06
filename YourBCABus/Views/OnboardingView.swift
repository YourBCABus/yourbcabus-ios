//
//  OnboardingView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var schoolID: String?
    
    var body: some View {
        NavigationView {
            OnboardingContentView(schoolID: $schoolID)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct OnboardingContentView: View {
    @Binding var schoolID: String?
    
    var body: some View {
        VStack {
            Text("Onboarding content")
            NavigationLink("Get started", destination: SchoolsView(schoolID: $schoolID))
        }
    }
}
