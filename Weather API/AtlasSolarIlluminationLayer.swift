import Foundation
import SwiftUI
import MapKit

struct AtlasSolarIlluminationLayer: MapContent {
    let ephemeris: SolarEphemeris
    
    var body: some MapContent {
        
        ForEach(fillSectors) { sector in
            MapPolygon(coordinates: sector.coordinates)
                .foregroundStyle(sector.color.opacity(sector.opacity))
        }
        
        ForEach(boundarySegments) { segment in
            MapPolyline(coordinates: segment.coordinates)
                .stroke(
                    segment.color.opacity(0.720),
                    style: StrokeStyle(
                        lineWidth: segment.lineWidth,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: segment.dashPattern
                    )
                )
        }
        
        Annotation(
            "Subsolar Point",
            coordinate: CLLocationCoordinate2D(
                latitude: ephemeris.subsolarCoordinate.latitudeDegrees,
                longitude: ephemeris.subsolarCoordinate.longitudeDegrees
            ),
            anchor: .center
        ) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.18))
                    .frame(width: 34, height: 34)
                
                Circle()
                    .stroke(.orange.opacity(0.65), lineWidth: 1)
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            .frame(width: 34, height: 34)
            .allowsHitTesting(false)
            .help("Subsolar Point")
        }
    }
    /// Turns one closed wilight boundary line into a filled region on the
    /// dark side of the earth.
    fileprivate var fillSectors: [AtlasSolarFillSector] {
        SolarIlluminationGeometry
            .twilightAltitudeDegrees
            .flatMap { altitude in
                makeFillSectors(for: altitude)
            }
    }
    /// Take this scientifically calculated twilight ring, determine which side is dark using the
    /// antisolar point, and convert that dark region into MapKit-friendly polygon wedges that can actually be shaded.
    fileprivate func makeFillSectors(
        for altitudeDegrees: Double
    ) -> [AtlasSolarFillSector] {
        let boundary =
            SolarIlluminationGeometry.boundary(
                atSolarAltitudeDegrees: altitudeDegrees,
                using: ephemeris,
                sampleCount: 144
            )
        
        let ring = Array(boundary.dropLast())
        
        guard ring.count >= 3 else {
            return []
        }
        
        let center = antisolarCoordinate
        let pointsPerSector = 12
        
        return stride(from: 0, to: ring.count, by: pointsPerSector)
            .map { startIndex in
                let endIndex =
                    min(startIndex + pointsPerSector, ring.count)
                
                var coordinates = [center]
                
                for index in startIndex...endIndex {
                    let coordinate = ring[index % ring.count]
                    
                    coordinates.append(
                        CLLocationCoordinate2D(
                            latitude: coordinate.latitudeDegrees,
                            longitude: coordinate.longitudeDegrees
                        )
                    )
                }
                coordinates.append(center)
                
                return AtlasSolarFillSector(
                    id: "\(altitudeDegrees):\(startIndex)",
                    solarAltitudeDegrees: altitudeDegrees,
                    coordinates: coordinates
                )
            }
    }
    
    fileprivate var antisolarCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: -ephemeris.subsolarCoordinate.latitudeDegrees,
            longitude: normalizedLongitude(ephemeris.subsolarCoordinate.longitudeDegrees + 180.00)
        )
    }
    
    fileprivate func normalizedLongitude(
        _ longitude: Double
    ) -> Double {
        var result = longitude.truncatingRemainder(dividingBy: 360.00)
        
        if result >= 180.0 {
            result -= 360.0
        }
        
        if result < -180.0 {
            result += 360.0
        }
        
        return result
    }
    
    fileprivate var boundarySegments: [AtlasSolarBoundarySegment] {
        SolarIlluminationGeometry
            .boundaries(using: ephemeris)
            .flatMap { boundary in
                splitAtAntimeridian(boundary)
            }
    }
    
    fileprivate func splitAtAntimeridian(
        _ boundary: SolarIlluminationBoundary
    ) -> [AtlasSolarBoundarySegment] {
        var coordinateGroups: [[CLLocationCoordinate2D]] = []
        
        var currentGroup: [CLLocationCoordinate2D] = []
        
        var previousLongitude: Double?
        
        for coordinate in boundary.coordinates {
            let mapCoordinate = CLLocationCoordinate2D(
                latitude: coordinate.latitudeDegrees,
                longitude: coordinate.longitudeDegrees
            )
            
            if let previousLongitude,
               abs(coordinate.longitudeDegrees - previousLongitude) > 180.00 {
                if currentGroup.count >= 2 {
                    coordinateGroups.append(currentGroup)
                }
                currentGroup = [mapCoordinate]
            } else {
                currentGroup.append(mapCoordinate)
            }
            
            previousLongitude = coordinate.longitudeDegrees
        }
        
        if currentGroup.count >= 2 {
            coordinateGroups.append(currentGroup)
        }
        
        return coordinateGroups.enumerated().map {
            index, coordinates in
            
            AtlasSolarBoundarySegment(
                id: "\(boundary.solarAltitudeDegrees):\(index)",
                solarAltitudeDegrees: boundary.solarAltitudeDegrees,
                coordinates: coordinates
            )
        }
    }
}

fileprivate struct AtlasSolarFillSector: Identifiable {
    let id: String
    let solarAltitudeDegrees: Double
    let coordinates: [CLLocationCoordinate2D]
    
    var color: Color {
        switch solarAltitudeDegrees {
        case 0.0:
            return Color(
                red: 0.10,
                green: 0.15,
                blue: 0.32
            )
            
        case -6.0:
            return Color(
                red: 0.08,
                green: 0.11,
                blue: 0.28
            )
            
        case -12.0:
            return Color(
                red: 0.05,
                green: 0.07,
                blue: 0.22
            )
        default:
            return .black
        }
    }
    
    var opacity: Double {
        switch solarAltitudeDegrees {
        case 0.0:
            return 0.10
        case -6.0:
            return 0.11
        case -12.0:
            return 0.13
        default:
            return 0.20
        }
    }
}

fileprivate struct AtlasSolarBoundarySegment: Identifiable {
    let id: String
    let solarAltitudeDegrees: Double
    let coordinates: [CLLocationCoordinate2D]
    
    var color: Color {
        switch solarAltitudeDegrees {
        case 0.0:
            return .orange
        case -6.0:
            return .cyan
        case -12.0:
            return .blue
        default:
            return .indigo
        }
    }
    
    var lineWidth: CGFloat {
        solarAltitudeDegrees == 0
        ? 1.8 : 1.2
    }
    
    var dashPattern: [CGFloat] {
        solarAltitudeDegrees == 0.0
        ? [] : [5, 4]
    }
}

