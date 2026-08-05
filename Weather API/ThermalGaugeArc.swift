/// Draws the upper portion of a semicircle from left to right.
///
/// Progress :
/// 0.0 = cold endpoint on the left, winter minimum minus 2 std dev.
/// 0.5 = top center
/// 1.0 = hot endpoint, summer maximum plus 2 std dev
///
import SwiftUI
import Foundation

nonisolated struct ThermalGaugeArc: Shape {
    var progress: Double
    
    var animatableData: Double {
        get { progress }
        
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let resolvedProgress =
            min(max(progress, 0.0), 1.0)
        
        let radius =
            min(rect.width / 2.0, rect.height)
        
        let center = CGPoint(
            x: rect.midX,
            y: rect.maxY
        )
        
        let segmentCount =
            max(Int(96.0 * resolvedProgress), 1)
        
        var path = Path()
        
        for segment in 0...segmentCount {
            let segmentProgress =
                resolvedProgress * Double(segment) / Double(segmentCount)
            
            let angle =
                Double.pi * (1.0 - segmentProgress)
            
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y - radius * CGFloat(sin(angle))
            )
            
            if segment == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        return path
    }
}
