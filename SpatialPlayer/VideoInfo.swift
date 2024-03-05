//
//  VideoInfo.swift
//  SpatialPlayer
//
//  Created by Michael Swanson on 2/6/24.
//

import Foundation
import CoreMedia

class VideoInfo {
    @Published var isSpatial: Bool = false
    @Published var size: CGSize = .zero
    @Published var projectionType: CMProjectionType?
    @Published var horizontalFieldOfView: Float?

    var sizeString: String {
        size == .zero ? "unspecified" :
        String(format: "%.0fx%.0f", size.width, size.height) +
        (isSpatial ? " per eye" : "")
    }

    var projectionTypeString: String {
        projectionType?.description ?? "unspecified"
    }
    
    var horizontalFieldOfViewString: String {
        horizontalFieldOfView.map { String(format: "%.0f°", $0) } ?? "unspecified"
    }
}
