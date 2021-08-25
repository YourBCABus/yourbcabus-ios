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

extension View {
    func onboardingStyle() -> some View {
        foregroundColor(Color("Primary")).padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(16)
    }
}

struct OnboardingContentView: View {
    @Binding var schoolID: String?
    
    var body: some View {
        VStack {
            Text("Welcome to YourBCABus").fontWeight(.bold).font(.largeTitle).multilineTextAlignment(.center)
            Spacer()
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Image(systemName: "bus.fill").font(.title).frame(width: 48)
                    VStack(alignment: .leading) {
                        Text("Know where your bus is").fontWeight(.bold)
                        Text("See all your buses in a list or on a map, with detailed information.").foregroundColor(.secondary)
                    }
                }
                HStack {
                    Image(systemName: "star.fill").font(.title).frame(width: 48)
                    VStack(alignment: .leading) {
                        Text("Star your favorite buses").fontWeight(.bold)
                        Text("Keep track of your favorite buses by starring them.").foregroundColor(.secondary)
                    }
                }
                HStack {
                    Image(systemName: "bell.fill").font(.title).frame(width: 48)
                    VStack(alignment: .leading) {
                        Text("End the guessing game").fontWeight(.bold)
                        Text("Get notified when your bus arrives.").foregroundColor(.secondary)
                    }
                }
            }.multilineTextAlignment(.leading).lineLimit(nil)
            Spacer()
            NavigationLink(destination: SchoolsView(schoolID: $schoolID)) {
                HStack {
                    Text("Get Started").fontWeight(.bold)
                    Image(systemName: "arrow.right")
                }.onboardingStyle()
            }
        }.padding(.horizontal).padding(.vertical, 64).environment(\.colorScheme, .dark).frame(maxWidth: .infinity).background(LinearGradient(colors: [Color("Primary"), Color("Primary Dark")], startPoint: UnitPoint(x: 0, y: 0), endPoint: UnitPoint(x: 1, y: 1))).edgesIgnoringSafeArea(.all).navigationBarHidden(true)
    }
}

struct OnboardingContentPreview: PreviewProvider {
    static var previews: some View {
        OnboardingView(schoolID: .constant(nil)).previewLayout(.device)
    }
}
