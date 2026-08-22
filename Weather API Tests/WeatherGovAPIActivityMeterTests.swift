import XCTest
@testable import Weather_API

@MainActor
final class
WeatherGovAPIActivityMeterTests:
    XCTestCase {

    func testSnapshotUsesRollingSixtySecondWindow()
        async {

        let meter =
            WeatherGovAPIActivityMeter()

        let now =
            Date(
                timeIntervalSince1970:
                    2_000_000_000
            )

        await meter.requestStarted(
            at:
                now.addingTimeInterval(-70)
        )

        await meter.requestFinished(
            succeeded: true,
            at:
                now.addingTimeInterval(-69)
        )

        await meter.recordObservationCacheHits(
            10,
            at:
                now.addingTimeInterval(-65)
        )

        await meter.requestStarted(
            at:
                now.addingTimeInterval(-45)
        )

        await meter.requestFinished(
            succeeded: true,
            at:
                now.addingTimeInterval(-44)
        )

        await meter.requestStarted(
            at:
                now.addingTimeInterval(-20)
        )

        await meter.requestFinished(
            succeeded: false,
            at:
                now.addingTimeInterval(-19)
        )

        await meter.requestStarted(
            at:
                now.addingTimeInterval(-5)
        )

        await meter.recordObservationCacheHits(
            4,
            at:
                now.addingTimeInterval(-10)
        )

        await meter.recordObservationCacheHits(
            3,
            at:
                now.addingTimeInterval(-1)
        )

        let snapshot =
            await meter.snapshot(at: now)

        XCTAssertEqual(
            snapshot.requestsLastMinute,
            3
        )

        XCTAssertEqual(
            snapshot.inFlightRequestCount,
            1
        )

        XCTAssertEqual(
            snapshot.successfulRequestsLastMinute,
            1
        )

        XCTAssertEqual(
            snapshot.failedRequestsLastMinute,
            1
        )

        XCTAssertEqual(
            snapshot.observationCacheHitsLastMinute,
            7
        )
    }

    func testActivityLevelThresholds() {
        XCTAssertEqual(
            snapshot(requestCount: 95).level,
            .normal
        )

        XCTAssertEqual(
            snapshot(requestCount: 96).level,
            .elevated
        )

        XCTAssertEqual(
            snapshot(requestCount: 159).level,
            .elevated
        )

        XCTAssertEqual(
            snapshot(requestCount: 160).level,
            .high
        )
    }

    private func snapshot(
        requestCount: Int
    ) -> WeatherGovAPIActivitySnapshot {

        WeatherGovAPIActivitySnapshot(
            requestsLastMinute:
                requestCount,
            inFlightRequestCount: 0,
            successfulRequestsLastMinute:
                requestCount,
            failedRequestsLastMinute: 0,
            observationCacheHitsLastMinute:
                0
        )
    }
}
