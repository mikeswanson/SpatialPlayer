//
//  VideoTools.swift
//  SpatialPlayer
//
//  Created by Michael Swanson on 2/6/24.
//

import AVFoundation
import CoreMedia
import Foundation
import RealityKit

struct VideoTools {
    
    /// Calculates the scale factor for a video plane to match a specified field of view at a given distance.
    /// - Parameters:
    ///   - videoWidth: The width of the video.
    ///   - videoHeight: The height of the video.
    ///   - zDistance: The distance from the viewer to the plane in the z-axis (towards the front).
    ///   - fovDegrees: The desired horizontal field of view in degrees.
    /// - Returns: The scale factor to apply to a video plane of width=1.
    static func calculateScaleFactor(
        videoWidth: Float, videoHeight: Float, zDistance: Float, fovDegrees: Float
    ) -> Float {
        let fovRadians = fovDegrees * .pi / 180.0
        let halfWidthAtZDistance = zDistance * tan(fovRadians / 2.0)
        let scaleFactor = 2.0 * halfWidthAtZDistance
        return scaleFactor
    }
    
    /// Generates a sphere mesh suitable for mapping an equirectangular video source.
    /// - Parameters:
    ///   - radius: The radius of the sphere.
    ///   - sourceHorizontalFov: Horizontal field of view of the source material.
    ///   - sourceVerticalFov: Vertical field of view of the source material.
    ///   - clipHorizontalFov: Horizontal field of view to clip.
    ///   - clipVerticalFov: Vertical field of view to clip.
    ///   - verticalSlices: The number of divisions around the sphere.
    ///   - horizontalSlices: The number of divisions from top to bottom.
    /// - Returns: A MeshResource representing the sphere.
    static func generateVideoSphere(
        radius: Float,
        sourceHorizontalFov: Float,
        sourceVerticalFov: Float,
        clipHorizontalFov: Float,
        clipVerticalFov: Float,
        verticalSlices: Int,
        horizontalSlices: Int
    ) -> MeshResource? {
        
        // Vertices
        var vertices: [simd_float3] = Array(
            repeating: simd_float3(), count: (verticalSlices + 1) * (horizontalSlices + 1))
        
        let verticalScale: Float = clipVerticalFov / 180.0
        let verticalOffset: Float = (1.0 - verticalScale) / 2.0
        
        let horizontalScale: Float = clipHorizontalFov / 360.0
        let horizontalOffset: Float = (1.0 - horizontalScale) / 2.0
        
        for y: Int in 0...horizontalSlices {
            let angle1 =
            ((Float.pi * (Float(y) / Float(horizontalSlices))) * verticalScale) + (verticalOffset * Float.pi)
            let sin1 = sin(angle1)
            let cos1 = cos(angle1)
            
            for x: Int in 0...verticalSlices {
                let angle2 =
                ((Float.pi * 2 * (Float(x) / Float(verticalSlices))) * horizontalScale)
                + (horizontalOffset * Float.pi * 2)
                let sin2 = sin(angle2)
                let cos2 = cos(angle2)
                
                vertices[x + (y * (verticalSlices + 1))] = SIMD3<Float>(
                    sin1 * cos2 * radius, cos1 * radius, sin1 * sin2 * radius)
            }
        }
        
        // Normals
        var normals: [SIMD3<Float>] = []
        for vertex in vertices {
            normals.append(-normalize(vertex))  // Invert to show on inside of sphere
        }
        
        // UVs
        var uvCoordinates: [simd_float2] = Array(repeating: simd_float2(), count: vertices.count)
        
        let uvHorizontalScale = clipHorizontalFov / sourceHorizontalFov
        let uvHorizontalOffset = (1.0 - uvHorizontalScale) / 2.0
        let uvVerticalScale = clipVerticalFov / sourceVerticalFov
        let uvVerticalOffset = (1.0 - uvVerticalScale) / 2.0
        
        for y in 0...horizontalSlices {
            for x in 0...verticalSlices {
                var uv: simd_float2 = [
                    (Float(x) / Float(verticalSlices)), 1.0 - (Float(y) / Float(horizontalSlices)),
                ]
                uv.x = (uv.x * uvHorizontalScale) + uvHorizontalOffset
                uv.y = (uv.y * uvVerticalScale) + uvVerticalOffset
                uvCoordinates[x + (y * (verticalSlices + 1))] = uv
            }
        }
        
        // Indices / triangles
        var indices: [UInt32] = []
        for y in 0..<horizontalSlices {
            for x in 0..<verticalSlices {
                let current: UInt32 = UInt32(x) + (UInt32(y) * UInt32(verticalSlices + 1))
                let next: UInt32 = current + UInt32(verticalSlices + 1)
                
                indices.append(current + 1)
                indices.append(current)
                indices.append(next + 1)
                
                indices.append(next + 1)
                indices.append(current)
                indices.append(next)
            }
        }
        
        var meshDescriptor = MeshDescriptor(name: "proceduralMesh")
        meshDescriptor.positions = MeshBuffer(vertices)
        meshDescriptor.normals = MeshBuffer(normals)
        meshDescriptor.primitives = .triangles(indices)
        meshDescriptor.textureCoordinates = MeshBuffer(uvCoordinates)
        
        let mesh = try? MeshResource.generate(from: [meshDescriptor])
        
        return mesh
    }
    
    /// Retrieves video information from an `AVAsset`.
    /// - Parameters:
    ///   - asset: The `AVAsset` instance to extract video information from.
    /// - Returns: An optional `VideoInfo` object containing the video's metadata, such as projection type and field of view.
    static func getVideoInfo(asset: AVAsset) async -> VideoInfo? {
            
        let videoInfo = VideoInfo()
        
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            print("No video track found")
            return nil
        }
        
        // Get video properties
        guard
            let (naturalSize, formatDescriptions, mediaCharacteristics) =
                try? await videoTrack.load(.naturalSize, .formatDescriptions, .mediaCharacteristics),
            let formatDescription = formatDescriptions.first
        else {
            print("Failed to load video properties")
            return nil
        }
        
        videoInfo.size = naturalSize
        videoInfo.isSpatial = mediaCharacteristics.contains(.containsStereoMultiviewVideo)
        
        let projection = VideoTools.getProjection(formatDescription: formatDescription)
        videoInfo.projectionType = projection.projectionType
        videoInfo.horizontalFieldOfView = projection.horizontalFieldOfView
        
        return videoInfo
    }
    
    /// Makes a projection `MeshResource` and transform based on `VideoInfo`.
    /// - Parameters:
    ///   - videoInfo: The `VideoInfo` instance used to generate the mesh.
    /// - Returns: A tuple containing the `MeshResource` and `Transform` for the video.
    static func makeVideoMesh(videoInfo: VideoInfo) async -> (mesh: MeshResource, transform: Transform)? {
        
        var mesh: MeshResource?
        var transform: Transform?
        
        let zDistance: Float = 50.0
        let horizontalFieldOfView = videoInfo.horizontalFieldOfView ?? 65.0 // reasonble default
        
        if videoInfo.projectionType == .equirectangular ||
            videoInfo.projectionType == .halfEquirectangular {
            
            mesh = VideoTools.generateVideoSphere(
                radius: 10000.0,
                sourceHorizontalFov: horizontalFieldOfView,
                sourceVerticalFov: 180.0,
                clipHorizontalFov: horizontalFieldOfView,
                clipVerticalFov: 180.0,
                verticalSlices: 60,
                horizontalSlices: Int(horizontalFieldOfView) / 3)
            
            transform = Transform(
                scale: .init(x: 1, y: 1, z: 1),
                rotation: .init(angle: -Float.pi / 2, axis: .init(x: 0, y: 1, z: 0)),
                translation: .init(x: 0, y: 0, z: 0))
        } else {

            // Assume rectilinear
            let width: Float = 1.0
            let height: Float = Float(videoInfo.size.height / videoInfo.size.width)
            
            mesh = await .generatePlane(width: width, depth: height)
            
            let scale = VideoTools.calculateScaleFactor(
                videoWidth: width, videoHeight: height, zDistance: zDistance, fovDegrees: horizontalFieldOfView)
            
            transform = Transform(
                scale: .init(x: scale, y: 1, z: scale),
                rotation: .init(angle: Float.pi / 2, axis: .init(x: 1, y: 0, z: 0)),
                translation: .init(x: 0, y: 0, z: -zDistance))
        }
        
        return (mesh: mesh!, transform: transform!)
    }
    
    /// Gets the projection type and horizontal field of view from a `CMFormatDescription`.
    /// - Parameters:
    ///  - formatDescription: `CMFormatDescription` from the video track.
    /// - Returns: A tuple containing the projection type and horizontal field of view.
    static func getProjection(formatDescription: CMFormatDescription) -> (
        projectionType: CMProjectionType?, horizontalFieldOfView: Float?
    ) {
        
        var projectionType: CMProjectionType?
        var horizontalFieldOfView: Float?
        
        if let extensions = CMFormatDescriptionGetExtensions(formatDescription) as Dictionary? {
            
            // FYI that the projection kind key is undocumented by Apple as of this writing.
            if let projectionKind = extensions["ProjectionKind" as CFString] as? String {
                projectionType = CMProjectionType(fromString: projectionKind) ?? .rectangular
            } else {
                print("ProjectionKind not found in format description extensions.")
            }
            
            if let horizontalFieldOfViewValue = extensions[kCMFormatDescriptionExtension_HorizontalFieldOfView]
                as? UInt32
            {
                horizontalFieldOfView = Float(horizontalFieldOfViewValue) / 1000.0
            } else {
                print("HorizontalFieldOfView not found in format description extensions.")
            }
        } else {
            print("No extensions found in format description.")
        }
        
        return (projectionType, horizontalFieldOfView)
    }
}
