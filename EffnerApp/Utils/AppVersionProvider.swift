//
//  AppVersionProvider.swift
//  EffnerApp
//

import Foundation

/// Provides a stable app version string in app runtime and SwiftUI previews.
enum AppVersionProvider {
    static var displayString: String {
        "Version \(marketingVersion) (\(buildNumber))"
    }

    private static var marketingVersion: String {
        value(for: "CFBundleShortVersionString", fallback: "-")
    }

    private static var buildNumber: String {
        value(for: kCFBundleVersionKey as String, fallback: "-")
    }

    private static func value(for key: String, fallback: String) -> String {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty {
            return value
        }

        // In previews/tests, `Bundle.main` can point to a host bundle.
        if let value = Bundle(for: BundleMarker.self).object(forInfoDictionaryKey: key) as? String, !value.isEmpty {
            return value
        }

        return fallback
    }
}

private final class BundleMarker: NSObject {}
