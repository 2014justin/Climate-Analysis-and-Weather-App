import Foundation
import Observation

/// Provider-neutral selection state for forecast playback.
///
/// Providers supply valid instants. Presentation code can select, step through,
/// or eventually play those instants without knowing whether they originated
/// from NWS, ECCC, or another forecast source.

@Observable
final class ForecastTimelineController {
    private(set) var availableInstants: [Date]
    private(set) var isPlaying = false
    
    @ObservationIgnored
    private var playbackTask:
        Task<Void, Never>?
    private(set) var selectedIndex: Int?
    
    init(
        availableInstants: [Date] = []
    ) {
        let sortedInstants = Array(Set(availableInstants)).sorted()
        
        self.availableInstants = sortedInstants
        self.selectedIndex = sortedInstants.isEmpty ? nil : 0
    }
    
    var selectedInstant: Date? {
        guard let selectedIndex,
              availableInstants.indices.contains(selectedIndex)
        else {
            return nil
        }
        
        return availableInstants[selectedIndex]
    }
    
    var canStepBackward: Bool {
        guard let selectedIndex else {
            return false
        }
        return selectedIndex > 0
    }
    
    var canStepForward: Bool {
        guard let selectedIndex else {
            return false
        }
        
        return selectedIndex < availableInstants.count - 1
    }
    
    func replaceWithHourlyForecastTimeline(
        startingAt referenceDate: Date,
        forecastHourCount: Int =
        ForecastHourlyTimeline.defaultForecastHourCount
    ) {
        replaceAvailableInstants(
            ForecastHourlyTimeline.instants(startingAt: referenceDate, forecastHourCount: forecastHourCount)
        )
    }
    
    func replaceAvailableInstants(
        _ newInstants: [Date]
    ) {
        /// Refreshing the timeline will now safely stop any existing playback task.
        pause()
        
        let previousInstant = selectedInstant
        
        availableInstants = Array(Set(newInstants)).sorted()
        
        guard !availableInstants.isEmpty == true else {
            selectedIndex = nil
            return
        }
        
        guard let previousInstant else {
            selectedIndex = 0
            return
        }
        
        selectedIndex = nearestIndex(to: previousInstant)
    }
    
    func select(
        index newIndex: Int
    ) {
        guard !availableInstants.isEmpty == true else {
            selectedIndex = nil
            return
        }
        
        selectedIndex = min(
            max(newIndex, 0),
            availableInstants.count - 1
        )
    }
    
    func stepBackward() {
        guard let selectedIndex else {
            return
        }
        
        select(index: selectedIndex - 1)
    }
    
    func stepForward() {
        guard let selectedIndex else {
            return
        }
        
        select(index: selectedIndex + 1)
    }
    
    func play() {
        guard !isPlaying, canStepForward else {
            return
        }
        
        isPlaying = true
        playbackTask?.cancel()
        
        /// Basically let asynchronous work access an object only if that
        /// object is still alive, without letting it play forever.
        playbackTask = Task {
            [weak self] in
            
            let clock = ContinuousClock()
            
            /// User can close the window, switch stations, stop playback, or
            /// deallocate the controller.
            while !Task.isCancelled {
                do {
                    try await clock.sleep(for: .milliseconds(250))
                } catch {
                    return
                }
                
                /// If self is nil, stop this task.
                guard let self else {
                    return
                }
                
                guard self.canStepForward else {
                    self.pause()
                    return
                }
                
                self.stepForward()
                
                if !self.canStepForward {
                    self.pause()
                    return
                }
            }
        }
    }
    
    func pause() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }
    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    fileprivate func nearestIndex(
        to instant: Date
    ) -> Int {
        availableInstants.indices.min {
            firstIndex,
            secondIndex in
            
            abs(
                availableInstants[firstIndex].timeIntervalSince(instant)
            )
            <
            abs(
                availableInstants[secondIndex].timeIntervalSince(instant)
            )
        }
        ?? 0
    }
}
