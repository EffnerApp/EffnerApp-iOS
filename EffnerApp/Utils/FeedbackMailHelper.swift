//
//  FeedbackMailHelper.swift
//  EffnerApp
//
//  Created by Luis Bros.
//

import Foundation
import UIKit

enum FeedbackMailHelper {
    static let recipient = "support@effner.app"

    /// Erzeugt eine standardkonforme mailto:-URL mit vorausgefülltem Empfänger, Betreff
    /// und einem Template im Body mit User-ID, Klassen, Geräte- und App-Metadaten sowie aktuellem Zeitstempel.
    static func feedbackURL(user: User? = UserSession.shared.user) -> URL {
        let appVersion = AppVersionProvider.displayString
        let systemVersion = UIDevice.current.systemVersion
        let device = deviceModelName()
        let userId = (user?.ssbId.isEmpty == false) ? user!.ssbId : "Nicht angemeldet"
        
        let klasses: String
        if let userKlasses = user?.klasses, !userKlasses.isEmpty {
            klasses = userKlasses.joined(separator: ", ")
        } else {
            klasses = "Keine"
        }
        
        let status = (user?.isAuthorized == true) ? "Angemeldet" : "Nicht angemeldet"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy, HH:mm:ss 'Uhr'"
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.timeZone = TimeZone.current
        let formattedDate = dateFormatter.string(from: Date())

        let subject = "EffnerApp Feedback (\(appVersion))"
        let body = """
        [Bitte beschreibe hier dein Feedback oder dein Problem]


        --- Technische Informationen (bitte nicht löschen) ---
        User-ID: \(userId)
        Klassen: \(klasses)
        App-Version: \(appVersion)
        iOS-Version: \(systemVersion)
        Gerät: \(device)
        Status: \(status)
        Uhrzeit: \(formattedDate)
        ------------------------------------------------------
        """
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\n", with: "\r\n")

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        return components.url ?? URL(string: "mailto:\(recipient)")!
    }

    private static func deviceModelName() -> String {
        // Im Simulator den simulierten Hardware-Identifier ermitteln
        if let simModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simModel) (Simulator)"
        }

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return identifier.isEmpty ? UIDevice.current.model : identifier
    }
}
