//
//  Timetable.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import Foundation

// MARK: - SSB Timetable Response
struct TimetableResponse: Decodable {
    let className: String
    let fetchedAt: String
    let slots: [TimetableSlot]
}

// MARK: - Subject
struct Subject: Decodable {
    let name: String
    let color: String
}

// MARK: - Timetable Slot
struct TimetableSlot: Decodable {
    let timeStart: String
    let timeEnd: String
    let monday: [Subject]
    let tuesday: [Subject]
    let wednesday: [Subject]
    let thursday: [Subject]
    let friday: [Subject]
    
    /// Returns the subjects for a given day index (0=Monday, 4=Friday)
    func subjects(for dayIndex: Int) -> [Subject] {
        switch dayIndex {
        case 0: return monday
        case 1: return tuesday
        case 2: return wednesday
        case 3: return thursday
        case 4: return friday
        default: return []
        }
    }
    
    /// Returns true if the slot has any subjects on at least one day
    var hasAnySubjects: Bool {
        !monday.isEmpty || !tuesday.isEmpty || !wednesday.isEmpty || !thursday.isEmpty || !friday.isEmpty
    }
    
    /// Parses timeStart into hour and minute components
    var startComponents: (hour: Int, minute: Int)? {
        parseTime(timeStart)
    }
    
    /// Parses timeEnd into hour and minute components
    var endComponents: (hour: Int, minute: Int)? {
        parseTime(timeEnd)
    }
    
    private func parseTime(_ time: String) -> (hour: Int, minute: Int)? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        return (hour, minute)
    }
}
