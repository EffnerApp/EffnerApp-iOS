//
//  TimetableMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import Foundation

struct MockTimetable {
    /// Standard Mock-Stundenplan für die Klasse 10a
    public static let mockTimetable: TimetableResponse = TimetableResponse(
        data: [
            Timetable(
                meta: [
                    SubjectMeta(subject: "Mathematik", color: "#3B82F6"),      // Blau
                    SubjectMeta(subject: "Deutsch", color: "#EF4444"),         // Rot
                    SubjectMeta(subject: "Englisch", color: "#10B981"),        // Grün
                    SubjectMeta(subject: "Physik", color: "#8B5CF6"),          // Lila
                    SubjectMeta(subject: "Chemie", color: "#F59E0B"),          // Orange
                    SubjectMeta(subject: "Biologie", color: "#14B8A6"),        // Türkis
                    SubjectMeta(subject: "Geschichte", color: "#D97706"),      // Braun
                    SubjectMeta(subject: "Sport", color: "#06B6D4"),           // Cyan
                    SubjectMeta(subject: "Informatik", color: "#6366F1"),      // Indigo
                    SubjectMeta(subject: "Kunst", color: "#EC4899"),           // Pink
                    SubjectMeta(subject: "Musik", color: "#F472B6"),           // Rosa
                    SubjectMeta(subject: "Geographie", color: "#84CC16")       // Lime
                ],
                lessons: [
                    // Montag - 6 Stunden
                    ["Mathematik", "Mathematik", "Deutsch", "Englisch", "Physik", "Physik", "", "", "", ""],
                    // Dienstag - 7 Stunden
                    ["Englisch", "Deutsch", "Deutsch", "Sport", "Sport", "Chemie", "Chemie", "", "", ""],
                    // Mittwoch - 6 Stunden
                    ["Biologie", "Biologie", "Mathematik", "Mathematik", "Geschichte", "Informatik", "", "", "", ""],
                    // Donnerstag - 8 Stunden (langer Tag)
                    ["Physik", "Chemie", "Englisch", "Englisch", "Deutsch", "Mathematik", "Kunst", "Kunst", "", ""],
                    // Freitag - 6 Stunden
                    ["Geschichte", "Geschichte", "Biologie", "Sport", "Sport", "Mathematik", "", "", "", ""]
                ],
                updatedAt: "2025-11-16T10:30:00Z",
                className: "10a"
            )
        ],
        schedule: []
    )
    
    /// Alternative Mock-Stundenpläne für verschiedene Klassen
    public static let mockFullDay: TimetableResponse = TimetableResponse(
        data: [
            Timetable(
                meta: [
                    SubjectMeta(subject: "Mathematik", color: "#3B82F6"),
                    SubjectMeta(subject: "Deutsch", color: "#EF4444"),
                    SubjectMeta(subject: "Englisch", color: "#10B981"),
                    SubjectMeta(subject: "Französisch", color: "#A855F7"),
                    SubjectMeta(subject: "Physik", color: "#8B5CF6"),
                    SubjectMeta(subject: "Chemie", color: "#F59E0B"),
                    SubjectMeta(subject: "Biologie", color: "#14B8A6"),
                    SubjectMeta(subject: "Geschichte", color: "#D97706"),
                    SubjectMeta(subject: "Geographie", color: "#84CC16"),
                    SubjectMeta(subject: "Sport", color: "#06B6D4"),
                    SubjectMeta(subject: "Informatik", color: "#6366F1"),
                    SubjectMeta(subject: "Kunst", color: "#EC4899"),
                    SubjectMeta(subject: "Musik", color: "#F472B6"),
                    SubjectMeta(subject: "Wirtschaft", color: "#059669")
                ],
                lessons: [
                    // Montag - voller Tag mit 9 Stunden
                    ["Mathematik", "Mathematik", "Deutsch", "Englisch", "Physik", "Chemie", "Informatik", "Informatik", "Wirtschaft", ""],
                    // Dienstag - 8 Stunden
                    ["Englisch", "Französisch", "Französisch", "Sport", "Sport", "Biologie", "Chemie", "Mathematik", "", ""],
                    // Mittwoch - 7 Stunden
                    ["Biologie", "Physik", "Mathematik", "Mathematik", "Geschichte", "Geographie", "Informatik", "", "", ""],
                    // Donnerstag - 9 Stunden
                    ["Deutsch", "Deutsch", "Englisch", "Französisch", "Sport", "Mathematik", "Kunst", "Kunst", "Musik", ""],
                    // Freitag - 6 Stunden (kurzer Tag)
                    ["Geschichte", "Geographie", "Biologie", "Mathematik", "Deutsch", "Englisch", "", "", "", ""]
                ],
                updatedAt: "2025-11-16T08:00:00Z",
                className: "11b"
            )
        ],
        schedule: []
    )
    
    /// Mock mit weniger Stunden (Unterstufe)
    public static let mockLightSchedule: TimetableResponse = TimetableResponse(
        data: [
            Timetable(
                meta: [
                    SubjectMeta(subject: "Mathematik", color: "#3B82F6"),
                    SubjectMeta(subject: "Deutsch", color: "#EF4444"),
                    SubjectMeta(subject: "Englisch", color: "#10B981"),
                    SubjectMeta(subject: "Biologie", color: "#14B8A6"),
                    SubjectMeta(subject: "Geschichte", color: "#D97706"),
                    SubjectMeta(subject: "Sport", color: "#06B6D4"),
                    SubjectMeta(subject: "Kunst", color: "#EC4899"),
                    SubjectMeta(subject: "Musik", color: "#F472B6")
                ],
                lessons: [
                    // Montag - 5 Stunden
                    ["Mathematik", "Deutsch", "Englisch", "Sport", "Sport", "", "", "", "", ""],
                    // Dienstag - 6 Stunden
                    ["Deutsch", "Deutsch", "Mathematik", "Biologie", "Kunst", "Kunst", "", "", "", ""],
                    // Mittwoch - 5 Stunden
                    ["Englisch", "Englisch", "Mathematik", "Geschichte", "Musik", "", "", "", "", ""],
                    // Donnerstag - 6 Stunden
                    ["Biologie", "Deutsch", "Englisch", "Mathematik", "Sport", "Sport", "", "", "", ""],
                    // Freitag - 4 Stunden (früher Schluss!)
                    ["Geschichte", "Mathematik", "Deutsch", "Englisch", "", "", "", "", "", ""]
                ],
                updatedAt: "2025-11-16T09:15:00Z",
                className: "7c"
            )
        ],
        schedule: []
    )
    
    /// Mock mit leeren Daten (für Tests)
    public static let mockEmpty: TimetableResponse = TimetableResponse(
        data: [],
        schedule: []
    )
}
