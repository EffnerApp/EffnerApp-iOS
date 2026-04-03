//
//  HolidaysView.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//

import SwiftUI
import Combine

struct HolidaysView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var holidaysCache: HolidaysCache

    init(isPreview: Bool = false) {
        if isPreview {
            HolidaysCache.shared.saveHolidays(MockHolidays.mockHolidays)
        }
    }

    var body: some View {
        BaseContentView(
            caches: [holidaysCache],
            navigationTitle: "Ferien",
            errorTitle: "Ferien nicht verfügbar",
            errorDescription: "Die Ferien konnten nicht geladen werden. Bitte versuche es später erneut.",
            useScrollViewReader: true,
            scrollToId: { _ in "futureHolidays" },
            isModal: true,
            content: { cache in
                if let holidays = holidaysCache.cachedHolidays {
                    List {
                        Section(header: HolidaySeparatorView()) {
                            ForEach(holidays.filter { isPastHoliday($0) }) { holiday in
                                HolidayRowView(holiday: holiday)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                        }
                        .id("pastHolidays")
                        
                        Section(header: HolidaySeparatorView(isPast: false)) {
                            ForEach(holidays.filter { !isPastHoliday($0) }) { holiday in
                                HolidayRowView(holiday: holiday)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                        }
                        .id("futureHolidays")
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(UIColor.systemBackground))
                }
            },
            skeletonView: {
                HolidaySkeletonView()
            }
        )
    }

    private func isPastHoliday(_ holiday: Holiday) -> Bool {
        let isoFormatter = ISO8601DateFormatter()
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "yyyy-MM-dd"

        if let endDate = isoFormatter.date(from: holiday.endsOn) ?? germanFormatter.date(from: holiday.endsOn) {
            return endDate < Date()
        }
        return false
    }
}

struct HolidayRowView: View {
    let holiday: Holiday
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: 0) {
                Text(formatDay(holiday.startsOn))
                    .font(.title2)
                Text(formatMonth(holiday.startsOn))
                    .font(.system(size: 17))
            }
            .frame(alignment: .center)
            

            VStack(alignment: .leading, spacing: 0) {
                Text(holiday.name)
                    .font(.title2)
                    .padding(.leading, 12)

                if holiday.startsOn != holiday.endsOn {
                    Text("bis \(formatDateShort(holiday.endsOn))")
                        .font(.subheadline)
                        .padding(.leading, 12)
                }
            }
        }
        .padding(.vertical, 0)
        .padding(.horizontal, 12)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "yyyy-MM-dd"
        
        return isoFormatter.date(from: dateString) ?? germanFormatter.date(from: dateString)
    }
    
    private func formatDay(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d."
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    private func formatDateShort(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return dateString }
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}

struct HolidaySeparatorView: View {
    var isPast: Bool = true

    var body: some View {
        HStack {
            if isPast {
                Text("Vergangene Ferien")
                    .font(.headline)
            } else {
                Text("Zukünftige Ferien")
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HolidaySkeletonView: View {
    var body: some View {
        List {
            ForEach(0..<5) { _ in
                HStack(alignment: .center) {
                    VStack(alignment: .center, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 16)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 16)
                    }
                    .padding(.leading, 12)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .listRowBackground(Color(UIColor.secondarySystemBackground))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.systemBackground))
        .redacted(reason: .placeholder)
    }
}

#Preview {
    HolidaysView(isPreview: true)
        .environmentObject(UserSession.shared)
        .environmentObject(HolidaysCache.shared)
}
