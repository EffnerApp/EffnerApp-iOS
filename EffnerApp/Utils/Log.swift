//
//  Log.swift
//  EffnerApp
//
//  Created by Luis Bros.
//

import OSLog

/// Provides domain-based loggers so that related components (Service, Cache, View)
/// share the same category and can be filtered together in Console.app.
///
/// Usage:
///   private static let logger = Log.timetable
///   logger.info("Cache refreshed.")
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "de.effnerapp.effner"

    // MARK: - Domain loggers

    static let auth         = Logger(subsystem: subsystem, category: "Auth")
    static let networking   = Logger(subsystem: subsystem, category: "Networking")
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
    static let keychain     = Logger(subsystem: subsystem, category: "Keychain")
    static let settings     = Logger(subsystem: subsystem, category: "Settings")

    // MARK: - Data domain loggers

    static let timetable    = Logger(subsystem: subsystem, category: "Timetable")
    static let exams        = Logger(subsystem: subsystem, category: "Exams")
    static let substitutions = Logger(subsystem: subsystem, category: "Substitutions")
    static let holidays     = Logger(subsystem: subsystem, category: "Holidays")
    static let documents    = Logger(subsystem: subsystem, category: "Documents")
    static let classes      = Logger(subsystem: subsystem, category: "Classes")
    static let config       = Logger(subsystem: subsystem, category: "Config")
    static let campusCafe   = Logger(subsystem: subsystem, category: "CampusCafe")
}
