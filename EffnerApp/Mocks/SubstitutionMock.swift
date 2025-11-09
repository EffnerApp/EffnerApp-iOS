//
//  SubstitutionMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation

struct MockSubstitution {
    public static let mockSubstitutionPlan: SubstitutionPlan = SubstitutionPlan(
        date: "08.11.2025",
        absent: [
            Absent(className: "10a", periods: [1, 2, 3]),
            Absent(className: "10b", periods: [4, 5]),
            Absent(className: "11c", periods: [2, 3, 4])
        ],
        hash: "mock-hash-12345",
        title: "Vertretungsplan vom 08.11.2025",
        infos: [
            "Unterrichtsende nach der 6. Stunde",
            "Die Mensa hat geöffnet",
            "Pausenaufsicht Herr Schmidt"
        ],
        substitutions: [
            Substitution(
                period: 1,
                teacher: "Müller",
                substitute: "Schmidt",
                room: "A101",
                info: "Mathematik statt Deutsch"
            ),
            Substitution(
                period: 2,
                teacher: "Meyer",
                substitute: "Fischer",
                room: "B205",
                info: "Selbststudium"
            ),
            Substitution(
                period: 3,
                teacher: "Weber",
                substitute: nil,
                room: nil,
                info: "Entfall"
            ),
            Substitution(
                period: 4,
                teacher: "Schulz",
                substitute: "Wagner",
                room: "C302",
                info: "Englisch - Raumwechsel"
            ),
            Substitution(
                period: 5,
                teacher: "Koch",
                substitute: "Becker",
                room: "A104",
                info: "Physik"
            )
        ],
        createdAt: Date()
    )
}
