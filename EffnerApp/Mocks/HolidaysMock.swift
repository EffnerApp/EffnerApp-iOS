//
//  HolidaysMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//

import Foundation

struct MockHolidays {
    static let mockHolidays : HolidayResponse = HolidayResponse(
        data: [
            Holiday(
                id: 4853,
                name: "Sommer",
                type: "school_vacation",
                startsOn: "2026-08-03",
                endsOn: "2026-09-14",
                locationId: 3,
                isPublicHoliday: false,
                isSchoolVacation: true
            ),
            Holiday(
                id: 4848,
                name: "Herbst",
                type: "school_vacation",
                startsOn: "2025-11-03",
                endsOn: "2025-11-07",
                locationId: 3,
                isPublicHoliday: false,
                isSchoolVacation: true
            ),
            Holiday(
                id: 4850,
                name: "Frühjahr",
                type: "school_vacation",
                startsOn: "2026-02-16",
                endsOn: "2026-02-20",
                locationId: 3,
                isPublicHoliday: false,
                isSchoolVacation: true
            ),
            Holiday(
                id: 4849,
                name: "Weihnachten",
                type: "school_vacation",
                startsOn: "2025-12-22",
                endsOn: "2026-01-05",
                locationId: 3,
                isPublicHoliday: false,
                isSchoolVacation: true
            ),
            Holiday(
                id: 4852,
                name: "Pfingsten",
                type: "school_vacation",
                startsOn: "2026-05-26",
                endsOn: "2026-06-05",
                locationId: 3,
                isPublicHoliday: false,
                isSchoolVacation: true
            ),
            Holiday(
                id: 4851,
                name: "Ostern",
                type: "school_vacation",
                startsOn: "2026-03-30",
                endsOn: "2026-04-10",
                locationId: 3,
                isPublicHoliday: false,
                isSchoolVacation: true
            )
        ],
        meta: Meta(
            location: Location(
                code: "BY",
                id: 3,
                links: Links(
                    self: "https://www.mehr-schulferien.de/api/v2.1/federal-states/bayern",
                    periods: "https://www.mehr-schulferien.de/api/v2.1/federal-states/bayern/periods",
                    icalendar: "https://www.mehr-schulferien.de/api/v2.1/federal-states/bayern/icalendar"
                ),
                name: "Bayern",
                type: "federal_state",
                slug: "bayern",
                parentLocationId: 1
            ),
            dateRange: DateRange(
                startDate: "2025-10-01",
                endDate: "2026-10-01"
            ),
            apiVersion: "2.1"
        )
    )
}
