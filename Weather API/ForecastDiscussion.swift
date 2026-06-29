/// Imports the most recent forecast discussion from NWS Las Vegas
/// makes it available in the app as a pop-up window.

import Foundation

struct ForecastDiscussionListResponse: Codable {
    let graph: [ForecastDiscussionSummary]
    
    enum CodingKeys: String, CodingKey {
        case graph = "@graph"
    }
}

struct ForecastDiscussionSummary: Codable {
    let id: String
    let issuanceTime: Date
    let productName: String
}

struct ForecastDiscussion: Codable {
    let id: String
    let issuingOffice: String
    let issuanceTime: Date
    let productName: String
    let productText: String
}

