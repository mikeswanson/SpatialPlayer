//
//  SpatialPlayerApp.swift
//  SpatialPlayer
//
//  Created by Michael Swanson on 2/6/24.
//

import SwiftUI

@main
struct SpatialPlayerApp: App {
    
    @StateObject private var viewModel = PlayerViewModel()
    
    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        
        ImmersiveSpace(id: "PlayerImmersiveSpace") {
            ImmersiveView()
                .environmentObject(viewModel)
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
