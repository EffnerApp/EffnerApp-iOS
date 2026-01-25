//
//  EffnerAppApp.swift
//  EffnerApp
//
//  Created by Luis Bros on 29.06.25.
//

import SwiftUI

@main
struct EffnerAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var session = UserSession.shared
    @StateObject private var classes = ClassesCache.shared
    @StateObject private var exams = ExamsCache.shared
    @StateObject private var substitutions = SubstitutionsCache.shared
    @StateObject private var timetables = TimetablesCache.shared
    @StateObject private var config = ConfigCache.shared
    @StateObject private var documents = DocumentsCache.shared
    @StateObject private var holidays = HolidaysCache.shared
    @StateObject private var notifications = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let user = session.user, user.isAuthorized {
                    // User hat eine Session und ist autorisiert → ContentView
                    ContentView()
                        .environmentObject(session)
                        .environmentObject(classes)
                        .environmentObject(exams)
                        .environmentObject(substitutions)
                        .environmentObject(timetables)
                        .environmentObject(config)
                        .environmentObject(documents)
                        .environmentObject(holidays)
                        .environmentObject(notifications)
                } else {
                    // Keine Session oder nicht autorisiert → LoginView
                    LoginView()
                        .environmentObject(session)
                        .environmentObject(classes)
                        .environmentObject(exams)
                        .environmentObject(substitutions)
                        .environmentObject(timetables)
                        .environmentObject(config)
                        .environmentObject(documents)
                }
            }
            .animation(.easeIn(duration: 0.3), value: session.user?.isAuthorized)
        }
    }
        
}


/*
 Weitere ideen von Gemini, die mir gut gefallen haben:
 - Noten-Rechner: Ein Tool, wo Schüler ihre Noten eintragen können und der Schnitt automatisch berechnet wird (nur lokal auf dem Gerät gespeichert) -> Vorallem für Oberstufe gut
 - Haptic Touch: Mehr Vibration überall bei touchen
 - Digitaler Schülerausweis: Schwer umzusetzen aber klingt eig ganz spannend
 - Ferien-Countdown: Und eine Kalenderartige Übersicht mit allen Ferien dieses und nächstes Schuljahr.
 
 
 1. Der Onboarding-Prozess (Die "Willkommensseite")
  Der erste Eindruck zählt. Statt eines langweiligen Formulars sollte der Prozess interaktiv und visuell sein.
  Der Vibe: Ein freundliches "Hi!" oder "Moin!" in großer, fetter Typografie (Apple Style).
  Die Klassenauswahl:
  Anstatt eines Dropdown-Menüs (zu bürokratisch), nutze große Auswahl-Kacheln oder ein iOS Picker Wheel.
  Step 1: Wähle die Stufe (5-13).
  Step 2: Wähle den Buchstaben (a, b, c...).
  Animation: Nach der Auswahl "fliegen" die Kacheln weg und das Dashboard baut sich mit einer sanften Animation auf.

 A. Der Speiseplan (Essen ist wichtig!)
  Swipe-Interface: Nutze eine Karten-Ansicht (wie bei TikTok oder Dating-Apps). Man sieht ein Bild (oder Icon) des Gerichts.
  Gamification: Ein kleiner "Lecker"-Button (Herz) und ein "Naja"-Button. Die App zeigt dann an: "80% der Schüler freuen sich auf dieses Gericht".
  Filter: Ein schnelles Icon-Set oben rechts für "Vegetarisch", "Vegan", "Kein Schwein".
 
 
 Der erste Tab sollte nicht einfach nur "Nachrichten" sein. Er sollte kontextbasiert sein und die Frage beantworten: "Was muss ich JETZT wissen?"

 HomeTab:
  Wir nennen diesen Tab "Heute" oder "Fokus".
  Aufbau des Dashboards (Bento-Grid Layout)
  Das Layout orientiert sich an Widgets (Bento-Box-Style), da Schüler dies von iOS gewohnt sind.
  Die "Jetzt & Gleich" Karte (Ganz oben, groß):
  Zeigt dynamisch an, was ansteht.
  Beispiel 07:50 Uhr: "Guten Morgen! Gleich: Mathe in R204 bei Frau Müller."
  Beispiel 13:00 Uhr: "Guten Appetit! Heute gibt es Spaghetti."
  Highlight: Wenn eine Vertretung ansteht, leuchtet diese Karte farbig (z.B. Orange) mit dem Hinweis "Entfall" oder "Raumänderung".
  
  Die "Timeline" Leiste:
  Eine horizontale Scroll-Leiste unter der Hauptkarte, die die nächsten 3 Stundenblöcke anzeigt. Visuell einfach gehalten (Fachkürzel + Raum).
 
  Das "Wichtig"-Widget:
  Zeigt nur relevante Push-Infos an. "Morgen: Klausur in Englisch!" oder "Hitzefrei ab 11:30".
 */
