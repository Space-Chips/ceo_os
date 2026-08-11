import DeviceActivity
import Foundation
import FamilyControls
import ManagedSettings

/// Classic daily-limit enforcement.
///
/// The host app schedules, per blocked entry, a `DeviceActivityEvent` whose
/// threshold is that entry's daily minute limit (see AppDelegate
/// `startClassicDailyLimitMonitoring`). When usage reaches the threshold iOS
/// runs `eventDidReachThreshold` here — and this callback must actually apply
/// the shield. It was previously empty, so classic daily limits never blocked
/// anything.
///
/// We mirror the host's shared storage EXACTLY (same app group + keys + entry
/// shape + selection decoding), so the two stay consistent: we persist the
/// triggered id and apply the shield immediately (the app may not be running);
/// the host's `applyEffectiveShield()` also unions triggered entries, so it
/// re-asserts the full shield on its next sync.
final class FocusActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let appGroupId = "group.com.wakeapp.ceoos"
    private let eventPrefix = "classic_daily_limit_event_"
    private let activityPrefix = "classic_daily_limit_activity_"
    private let entriesKey = "classic_daily_limit_entries_v1"
    private let triggeredIdsKey = "classic_daily_limit_triggered_ids_v1"

    private struct ClassicDailyLimitEntry: Codable {
        let id: String
        let selector: String
        let kind: String
        let limitMinutes: Int
    }

    /// Usage reached the daily limit for one entry → block it now.
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        NSLog("🟠CLASSICLIMIT ext threshold FIRED event=%@ activity=%@", event.rawValue, activity.rawValue)
        sharedDefaults()?.set(
            "event=\(event.rawValue) at=\(Date())",
            forKey: "classic_limit_debug_last_event"
        )

        let raw = event.rawValue
        guard raw.hasPrefix(eventPrefix) else {
            NSLog("🟠CLASSICLIMIT ext ignored (unexpected prefix)")
            return
        }
        let entryId = String(raw.dropFirst(eventPrefix.count))
        guard !entryId.isEmpty else { return }

        // Persist as triggered so the host keeps it blocked on its next sync.
        var triggered = loadTriggeredIds()
        triggered.insert(entryId)
        saveTriggeredIds(triggered)

        // Apply the shield immediately — the host app may be backgrounded/killed.
        guard let entry = loadEntries().first(where: { $0.id == entryId }),
              let selection = decodeSelection(entry.selector) else {
            NSLog("🟠CLASSICLIMIT ext FAILED load/decode id=%@ entries=%d", entryId, loadEntries().count)
            return
        }
        let beforeCount = store.shield.applications?.count ?? 0
        addToShield(selection)
        let afterCount = store.shield.applications?.count ?? 0
        NSLog(
            "🟠CLASSICLIMIT ext shield APPLIED id=%@ before=%d after=%d web=%d",
            entryId,
            beforeCount,
            afterCount,
            selection.webDomainTokens.count
        )
        sharedDefaults()?.set(
            "FIRED id=\(entryId) before=\(beforeCount) after=\(afterCount) at=\(Date())",
            forKey: "classic_limit_debug_last_fire"
        )
    }

    /// A new day's interval started for this entry → reset its daily limit:
    /// clear the "reached" flag and lift the shield tokens it uniquely
    /// contributed, so the app is usable again until today's limit is hit.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        NSLog("🟠CLASSICLIMIT ext intervalDidStart activity=%@", activity.rawValue)

        let raw = activity.rawValue
        guard raw.hasPrefix(activityPrefix) else { return }
        let entryId = String(raw.dropFirst(activityPrefix.count))
        guard !entryId.isEmpty else { return }

        var triggered = loadTriggeredIds()
        // If it wasn't triggered (e.g. monitoring just started mid-day), nothing
        // to reset.
        guard triggered.remove(entryId) != nil else { return }
        saveTriggeredIds(triggered)

        let entries = loadEntries()
        guard let entry = entries.first(where: { $0.id == entryId }),
              let selection = decodeSelection(entry.selector) else { return }

        // Only lift tokens that no OTHER still-triggered entry also needs, so we
        // don't unblock something another active daily limit is still shielding.
        var stillBlockedApps = Set<ApplicationToken>()
        var stillBlockedWeb = Set<WebDomainToken>()
        for other in entries where other.id != entryId && triggered.contains(other.id) {
            if let otherSelection = decodeSelection(other.selector) {
                stillBlockedApps.formUnion(otherSelection.applicationTokens)
                stillBlockedWeb.formUnion(otherSelection.webDomainTokens)
            }
        }
        removeFromShield(
            apps: selection.applicationTokens.subtracting(stillBlockedApps),
            web: selection.webDomainTokens.subtracting(stillBlockedWeb)
        )
    }

    // MARK: - Shield

    private func addToShield(_ selection: FamilyActivitySelection) {
        if !selection.applicationTokens.isEmpty {
            var apps = store.shield.applications ?? Set<ApplicationToken>()
            apps.formUnion(selection.applicationTokens)
            store.shield.applications = apps.isEmpty ? nil : apps
        }
        if !selection.webDomainTokens.isEmpty {
            var web = store.shield.webDomains ?? Set<WebDomainToken>()
            web.formUnion(selection.webDomainTokens)
            store.shield.webDomains = web.isEmpty ? nil : web
        }
    }

    private func removeFromShield(apps: Set<ApplicationToken>, web: Set<WebDomainToken>) {
        if !apps.isEmpty, var current = store.shield.applications {
            current.subtract(apps)
            store.shield.applications = current.isEmpty ? nil : current
        }
        if !web.isEmpty, var current = store.shield.webDomains {
            current.subtract(web)
            store.shield.webDomains = current.isEmpty ? nil : current
        }
    }

    // MARK: - Shared storage (mirrors AppDelegate)

    private func sharedDefaults() -> UserDefaults? { UserDefaults(suiteName: appGroupId) }

    private func loadEntries() -> [ClassicDailyLimitEntry] {
        guard let data = sharedDefaults()?.data(forKey: entriesKey),
              let entries = try? JSONDecoder().decode([ClassicDailyLimitEntry].self, from: data)
        else { return [] }
        return entries
    }

    private func loadTriggeredIds() -> Set<String> {
        Set(sharedDefaults()?.stringArray(forKey: triggeredIdsKey) ?? [])
    }

    private func saveTriggeredIds(_ ids: Set<String>) {
        sharedDefaults()?.set(Array(ids), forKey: triggeredIdsKey)
    }

    /// Same decoding as AppDelegate `decodeFamilyActivitySelectionPayload`:
    /// UTF-8 JSON first, then legacy URL-safe base64.
    private func decodeSelection(_ payload: String) -> FamilyActivitySelection? {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let utf8 = trimmed.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: utf8) {
            return decoded
        }

        var base64 = trimmed
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        if let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            return decoded
        }
        return nil
    }
}
