//
//  DateFormatter.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//

import Foundation

struct DateFormatterUtil {
    
    public static func formatToShortDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "d. MMM"
            formatter.locale = Locale(identifier: "de_DE")
            return formatter.string(from: date)
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
    
}


