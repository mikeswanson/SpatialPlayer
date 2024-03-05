//
//  ContentView.swift
//  SpatialPlayer
//
//  Created by Michael Swanson on 2/6/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        VStack {
            if viewModel.isImmersiveSpaceShown {
                Text("Spatial:").bold() + Text(" \(viewModel.videoInfo.isSpatial ? "Yes" : "No")")
                Text("Size:").bold() + Text(" \(viewModel.videoInfo.sizeString)")
                Text("Projection:").bold() + Text(" \(viewModel.videoInfo.projectionTypeString)")
                Text("Horizontal FOV:").bold() + Text(" \(viewModel.videoInfo.horizontalFieldOfViewString)")
                Toggle("Show in stereo", isOn: $viewModel.shouldPlayInStereo)
                    .fixedSize()
                    .disabled(!viewModel.isSpatialVideoAvailable)
                    .padding()
            } else {
                Text("Spatial Player").font(.title).padding()
                Text("by Michael Swanson")
                Link("https://blog.mikeswanson.com/spatial", destination: URL(string: "https://blog.mikeswanson.com/spatial")!)
                Text("An example spatial video player for MV-HEVC video.\nIt doesn't do much, but I hope it gets you started.").padding()
            }
            Button("Select Video", systemImage: "video.fill") {
                viewModel.isImmersiveSpaceShown = false
                viewModel.isDocumentPickerPresented = true
            }
            .padding()
            .sheet(isPresented: $viewModel.isDocumentPickerPresented) {
                DocumentPicker()
            }
        }
        .controlSize(.large)
        .onChange(of: viewModel.isImmersiveSpaceShown) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "PlayerImmersiveSpace") {
                    case .opened:
                        viewModel.isImmersiveSpaceShown = true
                    default:
                        viewModel.isImmersiveSpaceShown = false
                    }
                } else {
                    await dismissImmersiveSpace()
                    viewModel.isImmersiveSpaceShown = false
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PlayerViewModel())
    }
}
