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
            Text("Get notified when your bus arrives").fontWeight(.bold).font(.largeTitle).padding(.top, 64).padding(.horizontal)
            Spacer()
            Button("Enable notifications") {
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
            }.font(.title)
            Button("Not now") {
                isVisible = false
            }.padding(.bottom, 64)
        }.alert(isPresented: $showAlert) {
            Alert(title: Text("Enable Push Notifications"), message: Text("Please enable Push Notifications to receive bus alerts."), primaryButton: .default(Text("Settings")) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }, secondaryButton: .cancel(Text("Close")))
        }
    }
}
