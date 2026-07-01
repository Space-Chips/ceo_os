// ShieldActionExtension.swift
//
// Handles the taps coming from the shield UI rendered by
// `ShieldConfigurationExtension`. iOS hosts this extension in a tiny,
// short-lived process — there is no UI work we can do here; we can only
// mutate ManagedSettings and write to a shared App Group so the host app
// can react.
//
// Contract with the user (matches the labels in ShieldConfiguration):
//   primaryButton = "Get 5 more minutes"
//   secondaryButton = "Close"
//
// What we do on .primaryButtonPressed:
//   1. Wait 20 seconds before granting anything. The system shows the
//      button as visually pressed during this period so the user has time
//      to back off (Apple does not let us draw a progress bar inside the
//      shield; the 20 s is enforced by us sleeping the work queue).
//   2. Remove the tapped Application / WebDomain token from the global
//      shield store so iOS lets the user in.
//   3. Stamp an expiry timestamp in the shared App Group so the host app
//      (or `FocusActivityMonitorExtension`) can re-block the token once
//      the 5 minutes elapse. The actual re-block is wired in L4 — until
//      then the token stays unblocked until midnight (DeviceActivity
//      schedule resets daily). This is documented in the README.

import Foundation
import ManagedSettings
import UIKit

@available(iOS 16.0, *)
final class ShieldActionExtension: ShieldActionDelegate {

    private static let appGroupId = "group.com.wakeapp.ceoos"
    private static let extraTimePrefix = "wakeapp.extra_time."
    private static let extraTimeSeconds: TimeInterval = 5 * 60
    private static let frictionHoldSeconds: UInt64 = 20

    private let store = ManagedSettingsStore(named: .default)

    // MARK: - Application taps

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            Task.detached(priority: .userInitiated) { [weak self] in
                try? await Task.sleep(
                    nanoseconds: ShieldActionExtension.frictionHoldSeconds
                        * 1_000_000_000
                )
                self?.grantExtraTime(for: application)
                completionHandler(.close)
            }
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    // MARK: - Website taps

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            Task.detached(priority: .userInitiated) { [weak self] in
                try? await Task.sleep(
                    nanoseconds: ShieldActionExtension.frictionHoldSeconds
                        * 1_000_000_000
                )
                self?.grantExtraTime(for: webDomain)
                completionHandler(.close)
            }
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        // We never shield individual ActivityCategoryTokens directly today,
        // but the protocol requires us to return something safe.
        completionHandler(.close)
    }

    // MARK: - Grants

    private func grantExtraTime(for token: ApplicationToken) {
        var current = store.shield.applications ?? Set<ApplicationToken>()
        current.remove(token)
        store.shield.applications = current.isEmpty ? nil : current
        stampExtraTime(key: encodeToken(token))
    }

    private func grantExtraTime(for token: WebDomainToken) {
        var current = store.shield.webDomains ?? Set<WebDomainToken>()
        current.remove(token)
        store.shield.webDomains = current.isEmpty ? nil : current
        stampExtraTime(key: encodeToken(token))
    }

    private func encodeToken<T: Encodable>(_ token: T) -> String {
        guard let data = try? JSONEncoder().encode(token) else { return "" }
        return data.base64EncodedString()
    }

    private func stampExtraTime(key: String) {
        guard !key.isEmpty else { return }
        let defaults = UserDefaults(
            suiteName: ShieldActionExtension.appGroupId
        )
        let expiry =
            Date().addingTimeInterval(ShieldActionExtension.extraTimeSeconds)
        defaults?.set(
            expiry.timeIntervalSince1970,
            forKey: ShieldActionExtension.extraTimePrefix + key
        )
    }
}
