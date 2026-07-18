//
//  DateFormatter.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//

import Foundation

struct DateFormatterUtil {
    
    public static func formatToShortDate(_ dateString: String) -> String {
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "dd.MM.yyyy"
        
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = germanFormatter.date(from: dateString) ?? isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "d. MMM"
            displayFormatter.locale = Locale(identifier: "de_DE")
            return displayFormatter.string(from: date)
        }
        return dateString // Return the original string if parsing fails
    }
    
    public static func formatToShortDate(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    public static func formatDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "dd.MM.yyyy"

        if let date = isoFormatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        } else if let date = germanFormatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return isoString
    }

    public static func formatToWeekdayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd.MM.yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    public static func formatToWeekdayDate(_ dateString: String) -> String {
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "dd.MM.yyyy"

        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"

        if let date = germanFormatter.date(from: dateString) ?? isoFormatter.date(from: dateString) {
            return formatToWeekdayDate(date)
        }
        return dateString
    }

}


