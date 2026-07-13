//
//  SubstitutionMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation

struct MockSubstitution {
    public static let mockSubstitutionPlans: SubstitutionResponse = SubstitutionResponse(
        plans: [
            SubstitutionPlan(
                id: 20527,
                title: "Vertretungsplan für Freitag, 8.11.2025",
                planDate: "2025-11-08",
                createdAt: "2025-11-07T13:00:00",
                infos: [
                    "Unterrichtsende nach der 6. Stunde",
                    "Die Mensa hat geöffnet",
                    "Pausenaufsicht Herr Schmidt"
                ],
                absences: [
                    Absence(className: "10a", periods: "1,2,3"),
                    Absence(className: "10b", periods: "4,5"),
                    Absence(className: "11c", periods: "6,7")
                ],
                substitutions: [
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Müller",
                        substitute: "Schmidt",
                        period: "1",
                        room: "A101",
                        info: "Mathematik statt Deutsch"
                    ),
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Meyer",
                        substitute: "Fischer",
                        period: "2",
                        room: "B205",
                        info: "Selbststudium"
                    ),
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Weber",
                        substitute: nil,
                        period: "3",
                        room: nil,
                        info: "Entfall"
                    ),
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Schulz",
                        substitute: "Wagner",
                        period: "4",
                        room: "C302",
                        info: "Englisch - Raumwechsel"
                    ),
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Koch",
                        substitute: "Becker",
                        period: "55",
                        room: "A104",
                        info: "Physik"
                    )
                ]
            ),
            
            SubstitutionPlan(
                id: 20528,
                title: "Vertretungsplan für Samstag, 22.11.2026",
                planDate: "2026-11-22",
                createdAt: "2026-11-21T13:00:00",
                infos: [
                    "Unterrichtsende nach der 6. Stunde",
                    "Die Mensa hat geöffnet",
                    "Pausenaufsicht Herr Schmidt"
                ],
                absences: [
                    Absence(className: "10a", periods: "1,2,3"),
                    Absence(className: "10b", periods: "4,5"),
                    Absence(className: "11c", periods: "6,7")
                ],
                substitutions: [
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Müller",
                        substitute: "Schmidt",
                        period: "1",
                        room: "A101",
                        info: "Mathematik statt Deutsch"
                    ),
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Meyer",
                        substitute: "Fischer",
                        period: "2",
                        room: "B205",
                        info: "Selbststudium"
                    ),
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Weber",
                        substitute: nil,
                        period: "3",
                        room: nil,
                        info: "Entfall"
                    ),
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Schulz",
                        substitute: "Wagner",
                        period: "4",
                        room: "C302",
                        info: "Englisch - Raumwechsel"
                    ),
                    Substitution(
                        klassName: "13Q3",
                        teacher: "Koch",
                        substitute: "Becker",
                        period: "5",
                        room: "A104",
                        info: "Physik"
                    )
                ]
            )
        ]
    )
}
