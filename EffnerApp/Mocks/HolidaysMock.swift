//
//  HolidaysMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//

import Foundation

struct MockHolidays {
    static let mockHolidays: [Holiday] = [
        Holiday(
            name: "Weihnachten",
            startsOn: "2025-12-22",
            endsOn: "2026-01-05"
        ),
        Holiday(
            name: "Frühjahr",
            startsOn: "2026-02-16",
            endsOn: "2026-02-20"
        ),
        Holiday(
            name: "Ostern",
            startsOn: "2026-03-30",
            endsOn: "2026-04-10"
        ),
        Holiday(
            name: "Pfingsten",
            startsOn: "2026-05-26",
            endsOn: "2026-06-05"
        ),
        Holiday(
            name: "Sommer",
            startsOn: "2026-08-03",
            endsOn: "2026-09-14"
        ),
        Holiday(
            name: "Herbst",
            startsOn: "2026-11-02",
            endsOn: "2026-11-06"
        )
    ]
}
