/// Logic for the quality of life features for the climate charts such as cursor dragging,
/// automatic y-axis rescaling, and reset zoom.

import SwiftUI
import Charts

/// Provider-agnostic chart interaction overlay.
///
/// XValue may be Date, Int, Double, or any comparable quantity.
/// Swift charts plottable value.

struct ClimateChartRangeInteractionOverlay<XValue>: View
where XValue: Plottable & Comparable {
    
    let proxy: ChartProxy
    let xValueType: XValue.Type
    
    let onHover: (CGPoint) -> Void
    let onHoverEnded: () -> Void
    
    let onRangeChanged:
        (ClosedRange<XValue>) -> Void
    
    let onRangeEnded:
        (ClosedRange<XValue>) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if let plotFrameAnchor =
                proxy.plotFrame {
                
                let plotFrame =
                    geometry[plotFrameAnchor]
                
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            let plotLocation =
                                CGPoint(
                                    x: location.x - plotFrame.minX,
                                    y: location.y - plotFrame.minY
                                )
                            
                            guard plotFrame.contains(location) == true else {
                                
                                onHoverEnded()
                                return
                            }
                            
                            onHover(plotLocation)
                            
                        case .ended:
                            onHoverEnded()
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(
                            minimumDistance: 8
                        )
                        .onChanged { value in
                            guard let range =
                                    xRange(
                                        from: value,
                                        in: plotFrame
                                    ) else {
                                return
                            }
                            
                            onRangeChanged(range)
                        }
                        
                            .onEnded { value in
                                guard let range =
                                        xRange(
                                            from: value,
                                            in: plotFrame
                                        ) else {
                                    return
                                }
                                onRangeEnded(range)
                            }
                    )
            }
        }
    }
    
    /// Converts drag coordinates into an ordered range of chart-domain values.
    fileprivate func xRange(
        from value: DragGesture.Value,
        in plotFrame: CGRect
    ) -> ClosedRange<XValue>? {
        
        guard plotFrame.contains(
            value.startLocation
        ) else {
            return nil
        }
        
        let startX =
            value.startLocation.x - plotFrame.minX
        
        let unclampedCurrentX =
            value.location.x - plotFrame.minX
        
        let currentX =
            min(
                max(
                    unclampedCurrentX, 0
                ),
                plotFrame.width
            )
        
        guard let startValue: XValue =
                proxy.value(
                    atX: startX,
                    as: xValueType
                ),
              let currentValue: XValue =
                proxy.value(
                    atX: currentX,
                    as: xValueType
                ) else {
            return nil
        }
        
        if startValue <= currentValue {
            return startValue...currentValue
        } else {
            return currentValue...startValue
        }
    }
}

/// Stores reusable horizontal zoom state for a climate chart.
///
/// The graph remains responsible for validating and snapping a
/// proposed range before committing it.
struct ClimateChartZoomState<XValue>
where XValue: Comparable {
    
    /// The range currently displayed by the chart.
    /// nil means the complete domain is displayed.
    var committedDomain:
        ClosedRange<XValue>?
    
    /// The temporary range displayed while dragging.
    var pendingDomain:
        ClosedRange<XValue>?
    
    init(
        committedDomain:
            ClosedRange<XValue>? = nil,
        pendingDomain:
            ClosedRange<XValue>? = nil
    ) {
        self.committedDomain =
            committedDomain
        
        self.pendingDomain =
            pendingDomain
    }
    
    /// Whether the chart is currently showing a subset
    /// of its complete horizontal domain.
    var isZoomed: Bool {
        committedDomain != nil
    }
    
    /// Returns the committed zoom range when one exists,
    /// otherwise the graph's complete domain.
    func resolvedDomain(
        fullDomain: ClosedRange<XValue>
    ) -> ClosedRange<XValue> {
        committedDomain
            ?? fullDomain
    }
    
    /// Updates the translucent selection shown during dragging.
    mutating func updatePending(
        _ domain: ClosedRange<XValue>
    ) {
        pendingDomain = domain
    }
    
    /// Commits a range that the graph has already
    /// validated and snapped to real data points.
    mutating func commit(
        _ domain: ClosedRange<XValue>
    ) {
        committedDomain = domain
        pendingDomain = nil
    }
    
    /// Removes an unfinished drag without changing
    /// the committed zoom range.
    mutating func clearPending() {
        pendingDomain = nil
    }
    
    /// Restores the graph's complete horizontal domain.
    mutating func reset() {
        committedDomain = nil
        pendingDomain = nil
    }
}

/// Provider-neautral Y-axis calculator.

enum ClimateChartYDomainCalculator {
    
    static func domain(
        values: [Double],
        including referenceValues:
            [Double] = [],
        roundingStep: Double,
        padding: Double,
        minimumSpan: Double,
        lowerLimit: Double? = nil,
        upperLimit: Double? = nil,
        fallback: ClosedRange<Double>
    ) -> ClosedRange<Double> {
        guard roundingStep.isFinite == true,
              roundingStep > 0,
              padding.isFinite == true,
              padding >= 0,
              minimumSpan.isFinite == true,
              minimumSpan > 0 else {
            
            return fallback
        }
        
        let usableValues = (values + referenceValues).filter { value in
            value.isFinite == true
        }
        
        guard let minimum = usableValues.min(),
              let maximum = usableValues.max() else {
            
            return fallback
        }
        
        var rawLowerBound = minimum - padding
        
        var rawUpperBound = maximum + padding
        
        let rawSpan = rawUpperBound - rawLowerBound
        
        /// Prevents al almost flat data series from producing an
        /// unusably narrow vertical axis.
        if rawSpan < minimumSpan {
            let missingSpan =
                minimumSpan - rawSpan
            
            rawLowerBound -=
                missingSpan / 2.0
            rawUpperBound +=
                missingSpan / 2.0
        }
        
        var lowerBound =
            floor(rawLowerBound / roundingStep) * roundingStep
        
        var upperBound =
            ceil(rawUpperBound / roundingStep) * roundingStep
        
        /// Useful for cumulative quantities such as snowfall or DGGs whose axis should never
        /// be below zero.
        if let lowerLimit, lowerLimit.isFinite {
            lowerBound =
                max(lowerBound, lowerLimit)
        }
        
        if let upperLimit, upperLimit.isFinite {
            upperBound =
                min(upperBound, upperLimit)
        }
        
        guard lowerBound < upperBound else {
            return fallback
        }
        
        return lowerBound...upperBound
    }
}
