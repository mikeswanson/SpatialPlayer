//
//  CMProjectionType+String.swift
//  SpatialPlayer
//
//  Created by Michael Swanson on 2/6/24.
//

import Foundation
import CoreMedia

extension CMProjectionType {
    
    static let rectilinearString            = "Rectilinear"
    static let equirectangularString        = "Equirectangular"
    static let halfEquirectangularString    = "HalfEquirectangular"
    static let fisheyeString                = "Fisheye"

    init?(fromString string: String) {
        switch string {
        case CMProjectionType.rectilinearString:
            self = .rectangular
        case CMProjectionType.equirectangularString:
            self = .equirectangular
        case CMProjectionType.halfEquirectangularString:
            self = .halfEquirectangular
        case CMProjectionType.fisheyeString:
            self = .fisheye
        default:
            return nil
        }
    }

    var description: String {
        switch self {
        case .rectangular:
            return CMProjectionType.rectilinearString
        case .equirectangular:
            return CMProjectionType.equirectangularString
        case .halfEquirectangular:
            return CMProjectionType.halfEquirectangularString
        case .fisheye:
            return CMProjectionType.fisheyeString
        default:
            return "Unknown"
        }
    }
}
