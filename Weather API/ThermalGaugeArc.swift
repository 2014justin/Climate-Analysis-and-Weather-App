/// Draws the upper portion of a semicircle from left to right.
///
/// Progress :
/// 0.0 = cold endpoint on the left, winter minimum minus 2 std dev.
/// 0.5 = top center
/// 1.0 = hot endpoint, summer maximum plus 2 std dev
///
import SwiftUI
import Foundation

/// Thermal Gauge arc is a shape. To animate a shape, it repeatedly set its animatableData
/// Here's what is actually happeninig when the gauge is filled:
/// 1. SwiftUI reads animatableData at the start (0.0) and the end, say (0.71)
/// 2. Every single frame of the animation, SwiftUI interpolates a number in between and assigns it back, for example,
///     gauge.animatableData = 0.23....41...0.58
/// 3. Each assignment triggers the set doorman. Progress gets the new value, swiftUI called path(in:) , the
///     arc is redrawn at that exact sweep.
nonisolated struct ThermalGaugeArc: Shape {
    var progress: Double /// stored property.
    
    /// Computed property. The name doesn't hold a value, it holds behavior.
    /// This is the socket whereby SwiftUI plugs in each frame's value. Without it, the gauge would jump-cut
    /// from empty to full, SwiftUI would have no handle to grab, and it can't animate what it can't set.
    var animatableData: Double {
        get { progress }
        
        set { progress = newValue }
    }
    
    /// An ordered list of geometric instructions - data describing lines and curves. Path holds commands like
    /// move to (120.400) - the pen starts here
    /// line to (150,380) - draw a straight line ot here.
    ///
    /// so Path is the sheet of steps (pure data)
    /// SwiftUI is the dancer. It takes the sheet, and performs it on screen by filling the shape with color
    func path(in rect: CGRect) -> Path {
        
        /// Clamp progress to 0...1.
        let resolvedProgress = min(max(progress, 0.0), 1.0)
        
        /// A semicircle has to fit in the rect. Its radius can't be more than half the width and can't be more than the height.
        let radius = min(rect.width / 2.0, rect.height)
        
        let center = CGPoint(
            x: rect.midX,
            y: rect.maxY
        )
        
        /// How many straight lines do I use to fake a curve??
        let segmentCount =
            max(Int(96.0 * resolvedProgress), 1)
        
        var path = Path()
        
        for segment in 0...segmentCount {
            let segmentProgress =
                resolvedProgress * Double(segment) / Double(segmentCount)
            
            let angle =
                Double.pi * (1.0 - segmentProgress)
            
            /// Polar-cartesian conversion.
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y - radius * CGFloat(sin(angle))
            )
            
            if segment == 0 {
                path.move(to: point) /// first point: place the pen
            } else {
                path.addLine(to: point) /// every other point: draw a line to it
            }
        }
        
        return path
    }
}
