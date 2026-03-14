//
//  TimetableMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import Foundation

struct MockTimetable {
    /// Standard Mock-Stundenplan für die Klasse 6A
    public static let mockTimetable: TimetableResponse = TimetableResponse(
        className: "6A",
        fetchedAt: "2026-03-14T14:59:32.539797",
        slots: [
            TimetableSlot(timeStart: "08:00:00", timeEnd: "08:45:00",
                          monday: [Subject(name: "L", color: "#9E9E9E"), Subject(name: "F", color: "#0D47A1")],
                          tuesday: [Subject(name: "E", color: "#B71C1C")],
                          wednesday: [Subject(name: "KuSt", color: "#9E9E9E")],
                          thursday: [Subject(name: "Sm", color: "#9E9E9E"), Subject(name: "Sw", color: "#004D40")],
                          friday: [Subject(name: "E", color: "#B71C1C")]),
            TimetableSlot(timeStart: "08:45:00", timeEnd: "09:30:00",
                          monday: [Subject(name: "L", color: "#9E9E9E"), Subject(name: "F", color: "#0D47A1")],
                          tuesday: [Subject(name: "E", color: "#B71C1C")],
                          wednesday: [Subject(name: "KuSt", color: "#9E9E9E")],
                          thursday: [Subject(name: "Sm", color: "#9E9E9E"), Subject(name: "Sw", color: "#004D40")],
                          friday: [Subject(name: "L", color: "#9E9E9E"), Subject(name: "F", color: "#0D47A1")]),
            TimetableSlot(timeStart: "09:45:00", timeEnd: "10:30:00",
                          monday: [Subject(name: "M", color: "#6A1B9A")],
                          tuesday: [Subject(name: "D", color: "#1565C0")],
                          wednesday: [Subject(name: "M", color: "#6A1B9A")],
                          thursday: [Subject(name: "D", color: "#1565C0")],
                          friday: [Subject(name: "LInt", color: "#9E9E9E"), Subject(name: "FInt", color: "#9E9E9E"), Subject(name: "Inf", color: "#263238")]),
            TimetableSlot(timeStart: "10:30:00", timeEnd: "11:15:00",
                          monday: [Subject(name: "BSt", color: "#9E9E9E")],
                          tuesday: [Subject(name: "G", color: "#4E342E")],
                          wednesday: [Subject(name: "M", color: "#6A1B9A")],
                          thursday: [Subject(name: "D", color: "#1565C0")],
                          friday: [Subject(name: "LInt", color: "#9E9E9E"), Subject(name: "FInt", color: "#9E9E9E"), Subject(name: "Inf", color: "#263238")]),
            TimetableSlot(timeStart: "11:30:00", timeEnd: "12:15:00",
                          monday: [Subject(name: "E", color: "#B71C1C")],
                          tuesday: [Subject(name: "K", color: "#1A237E"), Subject(name: "Ev", color: "#283593"), Subject(name: "Ort", color: "#9E9E9E"), Subject(name: "Eth", color: "#546E7A")],
                          wednesday: [Subject(name: "L", color: "#9E9E9E"), Subject(name: "F", color: "#0D47A1")],
                          thursday: [Subject(name: "MuSt", color: "#9E9E9E")],
                          friday: [Subject(name: "K", color: "#1A237E"), Subject(name: "Ev", color: "#283593"), Subject(name: "Ort", color: "#9E9E9E"), Subject(name: "Eth", color: "#546E7A")]),
            TimetableSlot(timeStart: "12:15:00", timeEnd: "13:00:00",
                          monday: [Subject(name: "MuSt", color: "#9E9E9E")],
                          tuesday: [Subject(name: "M", color: "#6A1B9A")],
                          wednesday: [Subject(name: "D", color: "#1565C0")],
                          thursday: [Subject(name: "BSt", color: "#9E9E9E")],
                          friday: [Subject(name: "G", color: "#4E342E")]),
            TimetableSlot(timeStart: "13:00:00", timeEnd: "13:45:00",
                          monday: [], tuesday: [], wednesday: [],
                          thursday: [], friday: []),
            TimetableSlot(timeStart: "13:45:00", timeEnd: "14:30:00",
                          monday: [Subject(name: "SSp", color: "#9E9E9E")],
                          tuesday: [], wednesday: [],
                          thursday: [], friday: []),
            TimetableSlot(timeStart: "14:30:00", timeEnd: "15:15:00",
                          monday: [Subject(name: "SSp", color: "#9E9E9E")],
                          tuesday: [], wednesday: [],
                          thursday: [], friday: []),
            TimetableSlot(timeStart: "15:15:00", timeEnd: "16:00:00",
                          monday: [], tuesday: [], wednesday: [],
                          thursday: [], friday: []),
            TimetableSlot(timeStart: "16:00:00", timeEnd: "16:45:00",
                          monday: [], tuesday: [], wednesday: [],
                          thursday: [], friday: [])
        ]
    )
    
    /// Mock mit leeren Daten (für Tests)
    public static let mockEmpty: TimetableResponse = TimetableResponse(
        className: "",
        fetchedAt: "",
        slots: []
    )
}
