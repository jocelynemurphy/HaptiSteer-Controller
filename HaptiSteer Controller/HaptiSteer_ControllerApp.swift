//
//  HaptiSteer_ControllerApp.swift
//  HaptiSteer Controller
//
//  Created by Coding on 2024-10-26.
//

import SwiftUI

@main
struct HaptiSteer_ControllerApp: App {
    @StateObject private var bleManager = BLEManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
        }
    }
}
