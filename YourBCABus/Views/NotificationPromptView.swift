//
//  NotificationPromptView.swift
//  NotificationPromptView
//
//  Created by Anthony Li on 8/20/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct NotificationPromptView: View {
    @Binding var isVisible: Bool
    @State var showAlert = false
    @Binding var busArrivalNotifications: Bool
    
    var body: some View {
        VStack {
            Text("You just starred a bus!").fontWeight(.bold).font(.title).padding(.bottom, 12)
            Text("Would you like to be notified when a starred bus arrives?")
            Spacer()
            Image(systemName: "bell.fill").font(.system(size: 128))
            Spacer()
            Button {
                UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                    switch settings.authorizationStatus {
                    case .denied:
                        DispatchQueue.main.async {
                            showAlert = true
                        }
                    case .notDetermined:
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
                            DispatchQueue.main.async {
                                if authorized {
                                    busArrivalNotifications = true
                                    isVisible = false
                                } else {
                                    showAlert = true
                                }
                            }
                        })
                    default:
                        DispatchQueue.main.async {
                            busArrivalNotifications = true
                            isVisible = false
                        }
                    }
                })
            } label: {
                Text("Enable notifications").font(.headline).fontWeight(.bold).onboardingStyle()
            }
            Button("Not now") {
                busArrivalNotifications = false
                isVisible = false
            }.foregroundColor(.primary)
            Text("You can change this option in Settings.").foregroundColor(.secondary).padding(.top, 16).font(.caption)
        }.alert(isPresented: $showAlert) {
            Alert(title: Text("Enable Push Notifications"), message: Text("Please enable Push Notifications to receive bus alerts."), primaryButton: .default(Text("Settings")) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }, secondaryButton: .cancel(Text("Close")))
        }.padding(.horizontal).padding(.top, 64).padding(.bottom, 48).environment(\.colorScheme, .dark).frame(maxWidth: .infinity).background(LinearGradient(colors: [Color("Primary"), Color("Primary Dark")], startPoint: UnitPoint(x: 0, y: 0), endPoint: UnitPoint(x: 1, y: 1))).edgesIgnoringSafeArea(.all).multilineTextAlignment(.center)
    }
}
