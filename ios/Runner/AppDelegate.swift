import UIKit
import Flutter
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI
import UserNotifications
import ObjectiveC.runtime
#if canImport(adaptive_platform_ui)
import adaptive_platform_ui
#endif
#if canImport(app_links)
import app_links
#endif
#if canImport(flutter_local_notifications)
import flutter_local_notifications
#endif
#if canImport(google_sign_in_ios)
import google_sign_in_ios
#endif
#if canImport(home_widget)
import home_widget
#endif
#if canImport(image_picker_ios)
import image_picker_ios
#endif
#if canImport(path_provider_foundation)
import path_provider_foundation
#endif
#if canImport(purchases_flutter)
import purchases_flutter
#endif
#if canImport(shared_preferences_foundation)
import shared_preferences_foundation
#endif
#if canImport(sign_in_with_apple)
import sign_in_with_apple
#endif
#if canImport(url_launcher_ios)
import url_launcher_ios
#endif
#if canImport(workmanager_apple)
import workmanager_apple
#endif

@available(iOS 15.0, *)
private func decodeFamilyActivitySelectionPayload(_ payload: String) -> FamilyActivitySelection? {
    let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if let utf8Data = trimmed.data(using: .utf8),
       let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: utf8Data) {
        return decoded
    }

    var legacyBase64 = trimmed
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let remainder = legacyBase64.count % 4
    if remainder > 0 {
        legacyBase64 += String(repeating: "=", count: 4 - remainder)
    }
    if let base64Data = Data(base64Encoded: legacyBase64, options: .ignoreUnknownCharacters),
       let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: base64Data) {
        return decoded
    }

    return nil
}

@available(iOS 16.0, *)
private struct NativeBlockedWebsiteTokenIconView: View {
    let token: WebDomainToken

    var body: some View {
        Label(token)
            .labelStyle(.iconOnly)
            .imageScale(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

@available(iOS 16.0, *)
private struct NativeBlockedAppTokenIconView: View {
    let token: ApplicationToken

    var body: some View {
        Label(token)
            .labelStyle(.iconOnly)
            .imageScale(.large)
            .font(.system(size: 34, weight: .semibold))
            .scaleEffect(2.25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

@available(iOS 16.0, *)
private final class BlockedAppTokenIconPlatformView: NSObject, FlutterPlatformView {
    private let container: UIView

    init(frame: CGRect, viewId: Int64, args: Any?) {
        container = UIView(frame: frame)
        container.backgroundColor = .clear
        super.init()

        let arguments = args as? [String: Any]
        let payload = (arguments?["payload"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let isDarkTheme = (arguments?["isDarkTheme"] as? Bool) ?? true

        if let token = BlockedAppTokenLabelPlatformView.decodeApplicationToken(from: payload) {
            let host = UIHostingController(
                rootView: NativeBlockedAppTokenIconView(token: token)
            )
            host.view.backgroundColor = .clear
            host.overrideUserInterfaceStyle = isDarkTheme ? .dark : .light
            host.view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: container.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }
    }

    func view() -> UIView {
        container
    }
}

@available(iOS 16.0, *)
private final class BlockedAppTokenIconPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        BlockedAppTokenIconPlatformView(frame: frame, viewId: viewId, args: args)
    }
}

@available(iOS 15.0, *)
public class FocusEngine: NSObject {
    public static let shared = FocusEngine()
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let plansStorageKey = "planned_focus_sessions_v1"
    private let selectionStorageKey = "focus_selection_json_v1"
    private let focusEnabledStorageKey = "focus_shield_enabled_v1"
    private let scheduledFocusEnabledStorageKey = "scheduled_focus_enabled_v1"
    private let classicSelectionStorageKey = "classic_selection_payloads_v1"
    private let classicEnabledStorageKey = "classic_shield_enabled_v1"
    private let classicPauseSelectionStorageKey = "classic_pause_selection_payloads_v1"
    private let classicPauseEnabledStorageKey = "classic_pause_enabled_v1"
    private let classicRestPeriodsStorageKey = "classic_rest_periods_v1"
    private let classicDailyLimitEntriesStorageKey = "classic_daily_limit_entries_v1"
    private let classicDailyLimitTriggeredIdsStorageKey = "classic_daily_limit_triggered_ids_v1"
    private let ceoEnabledStorageKey = "ceo_shield_enabled_v1"
    private let classicWebsiteDomainsStorageKey = "classic_website_domains_v1"
    private let classicPauseWebsiteDomainsStorageKey =
        "classic_pause_website_domains_v1"
    private let appGroupId = "group.com.wakeapp.ceoos"
    private let ceoAlwaysAllowedBundleIds: Set<String> = [
        "com.apple.mobilephone",
        "com.apple.MobileSMS",
        "com.apple.mobilecal"
    ]
    private let ceoForceBlockedBundleIds: Set<String> = [
        "com.withopal.opal",
        "com.apple.facetime",
        "com.apple.Maps",
        "com.apple.Passbook",
        "com.apple.Fitness",
        "com.apple.findmy",
        "com.apple.Home",
        "com.apple.DocumentsApp",
        "com.apple.appleseed.FeedbackAssistant",
        "com.apple.tips"
    ]
    private let planPrefixWarn = "focus_plan_warn_"
    private let planPrefixStart = "focus_plan_start_"
    private let planActivityPrefix = "focus_plan_activity_"
    private let classicRestActivityPrefix = "classic_rest_activity_"
    private let classicDailyLimitActivityPrefix = "classic_daily_limit_activity_"
    private let classicDailyLimitEventPrefix = "classic_daily_limit_event_"
    private let screenTimeThemeKeyPrefix = "screen_time_theme_"
    
    // Store selection for persistence during session
    private var selection = FamilyActivitySelection()
    private var activePickerResult: FlutterResult?
    private var activePickerDelegate: PickerPresentationDelegate?
    private weak var activePickerHost: UIViewController?
    private var activePickerRequiresWebDomains = false

    private struct PlannedSession: Codable {
        let id: String
        let title: String
        let date: String
        let time: String
        let durationMinutes: Int
        let weekly: Bool
    }

    private struct PlannedClassicRest: Codable {
        let id: String
        let startMillis: Int64
        let endMillis: Int64
    }

    private struct ClassicDailyLimitEntry: Codable {
        let id: String
        let selector: String
        let kind: String
        let limitMinutes: Int
    }
    
    private func requestPermissions(result: @escaping FlutterResult) {
        Task {
            do {
                try await center.requestAuthorization(for: .individual)
                requestLocalNotificationsIfNeeded()
                result(true)
            } catch {
                print("Authorization failed: \(error)")
                result(false)
            }
        }
    }

    private func authorizationStatusCode() -> String {
        switch center.authorizationStatus {
        case .approved:
            return "approved"
        case .denied:
            return "denied"
        case .notDetermined:
            return "not_determined"
        @unknown default:
            return "unsupported"
        }
    }

    private func parseSession(_ raw: [String: Any]) -> PlannedSession? {
        guard let id = raw["id"] as? String,
              let date = raw["date"] as? String,
              let time = raw["time"] as? String else {
            return nil
        }
        let title = (raw["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let duration = (raw["durationMinutes"] as? Int) ?? 45
        let weekly = (raw["weekly"] as? Bool) ?? false

        return PlannedSession(
            id: id,
            title: (title?.isEmpty == false ? title! : "Focus Session"),
            date: date,
            time: time,
            durationMinutes: max(5, min(duration, 180)),
            weekly: weekly
        )
    }

    private func parseDate(_ date: String, _ time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let full = "\(date) \(time)"
        if let parsed = formatter.date(from: full) {
            return parsed
        }
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: "\(date) \(time.prefix(5))")
    }

    private func savePlans(_ plans: [PlannedSession]) {
        if let data = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(data, forKey: plansStorageKey)
        }
    }

    private func calendarTrigger(for date: Date, weekly: Bool) -> UNCalendarNotificationTrigger {
        let calendar = Calendar.current
        if weekly {
            let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    private func clearPlannedNotifications(completion: @escaping () -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let ids = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(self.planPrefixWarn) || $0.hasPrefix(self.planPrefixStart) }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
            completion()
        }
    }

    private func clearPlannedDeviceActivities() {
        let active = deviceActivityCenter.activities
        let names = active.filter { $0.rawValue.hasPrefix(planActivityPrefix) }
        guard !names.isEmpty else { return }
        deviceActivityCenter.stopMonitoring(Array(names))
    }

    private func startPlannedDeviceActivity(for session: PlannedSession, startDate: Date) {
        let calendar = Calendar.current
        let endDate = startDate.addingTimeInterval(TimeInterval(max(5, session.durationMinutes)) * 60.0)

        let startComponents: DateComponents
        let endComponents: DateComponents

        if session.weekly {
            startComponents = calendar.dateComponents([.weekday, .hour, .minute], from: startDate)
            endComponents = calendar.dateComponents([.weekday, .hour, .minute], from: endDate)
        } else {
            startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
            endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: session.weekly
        )

        do {
            let name = DeviceActivityName("\(planActivityPrefix)\(session.id)")
            try deviceActivityCenter.startMonitoring(name, during: schedule)
        } catch {
            print("Failed to schedule DeviceActivity for \(session.id): \(error)")
        }
    }

    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        trigger: UNNotificationTrigger,
        userInfo: [AnyHashable: Any]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule focus notification \(identifier): \(error)")
            }
        }
    }

    private func syncPlannedSessions(args: [String: Any]?, result: @escaping FlutterResult) {
        requestLocalNotificationsIfNeeded()
        let rawSessions = args?["sessions"] as? [[String: Any]] ?? []
        let parsed = rawSessions.compactMap { parseSession($0) }
        savePlans(parsed)
        clearPlannedDeviceActivities()

        clearPlannedNotifications { [weak self] in
            guard let self = self else { return }
            for session in parsed {
                guard let startDate = self.parseDate(session.date, session.time) else { continue }
                if !session.weekly && startDate <= Date() {
                    continue
                }
                let warningDate = startDate.addingTimeInterval(-5 * 60)
                self.startPlannedDeviceActivity(for: session, startDate: startDate)

                let warnTrigger = self.calendarTrigger(for: warningDate, weekly: session.weekly)
                let startTrigger = self.calendarTrigger(for: startDate, weekly: session.weekly)

                let warnId = "\(self.planPrefixWarn)\(session.id)"
                let startId = "\(self.planPrefixStart)\(session.id)"

                self.scheduleNotification(
                    identifier: warnId,
                    title: "Focus in 5 minutes",
                    body: "\(session.title) starts soon.",
                    trigger: warnTrigger,
                    userInfo: [
                        "focus_plan_type": "warning",
                        "focus_plan_id": session.id,
                        "focus_plan_duration": session.durationMinutes
                    ]
                )

                self.scheduleNotification(
                    identifier: startId,
                    title: "Focus session started",
                    body: "\(session.title) is now active.",
                    trigger: startTrigger,
                    userInfo: [
                        "focus_plan_type": "start",
                        "focus_plan_id": session.id,
                        "focus_plan_duration": session.durationMinutes
                    ]
                )
            }
            result(true)
        }
    }

    func handlePlannedNotification(_ userInfo: [AnyHashable: Any]) {
        guard let type = (userInfo["focus_plan_type"] as? String)?.lowercased() else { return }
        if type == "start" {
            sharedDefaults()?.set(true, forKey: scheduledFocusEnabledStorageKey)
            applyEffectiveShield()
        }
    }

    private func requestLocalNotificationsIfNeeded() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            // Best-effort; no hard failure for focus scheduling.
        }
    }
    
    private func sharedDefaults() -> UserDefaults? {
        guard hasAppGroupAccess() else {
            return nil
        }
        return UserDefaults(suiteName: appGroupId)
    }

    private func saveScreenTimeTheme(tokens: [String: String]) {
        guard let defaults = sharedDefaults() else { return }
        for (key, value) in tokens {
            defaults.set(value, forKey: "\(screenTimeThemeKeyPrefix)\(key)")
        }
    }

    private func readScreenTimeThemeValue(_ key: String) -> UIColor? {
        guard let defaults = sharedDefaults(),
              let raw = defaults.string(forKey: "\(screenTimeThemeKeyPrefix)\(key)") else {
            return nil
        }
        return UIColor(hexString: raw)
    }

    private func hasAppGroupAccess() -> Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) != nil
    }

    private func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var topController = keyWindow?.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        return topController
    }

    private func finishPicker(with selection: FamilyActivitySelection?) {
        guard let result = activePickerResult else { return }
        let requiresWebDomains = activePickerRequiresWebDomains
        activePickerResult = nil
        activePickerDelegate = nil
        activePickerHost = nil
        activePickerRequiresWebDomains = false

        guard let selection else {
            result(nil)
            return
        }
        if requiresWebDomains && selection.webDomainTokens.isEmpty {
            // Treat an empty website pick as a graceful no-op instead of an error.
            // This prevents Flutter-side flow breakage when the user exits the picker
            // without selecting a website token.
            result([])
            return
        }
        if !requiresWebDomains {
            guard !selection.applicationTokens.isEmpty else {
                result(FlutterError(
                    code: "NO_APPS_SELECTED",
                    message: "Select at least one app to continue.",
                    details: nil
                ))
                return
            }
            var payloads: [[String: Any]] = []
            for token in selection.applicationTokens {
                var single = FamilyActivitySelection()
                single.applicationTokens = [token]
                guard let encoded = encodeSelection(single) else { continue }
                let app = Application(token: token)
                let appName = app.localizedDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines)
                let bundleIdentifier = app.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
                payloads.append([
                    "payload": encoded,
                    "appName": (appName?.isEmpty == false ? appName! : (bundleIdentifier?.isEmpty == false ? bundleIdentifier! : "")),
                    "bundleIdentifier": bundleIdentifier ?? ""
                ])
            }
            if payloads.isEmpty {
                result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode selection", details: nil))
            } else {
                result(payloads)
            }
            return
        }

        var payloads: [[String: Any]] = []
        for token in selection.webDomainTokens {
            var single = FamilyActivitySelection()
            single.webDomainTokens = [token]
            if let encoded = encodeSelection(single) {
                let domain = WebDomain(token: token).domain ?? ""
                payloads.append([
                    "payload": encoded,
                    "domain": domain
                ])
            }
        }
        if payloads.isEmpty {
            result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode selection", details: nil))
        } else {
            result(payloads)
        }
    }

    private func hasSelection(_ selection: FamilyActivitySelection) -> Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    private func normalizedDomains(_ domains: [String]) -> [String] {
        var deduped: [String] = []
        for raw in domains {
            guard let normalized = normalizedDomain(raw) else {
                continue
            }
            if !deduped.contains(normalized) {
                deduped.append(normalized)
            }
        }
        return deduped
    }

    private func normalizedDomain(_ raw: String) -> String? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.isEmpty {
            return nil
        }

        if value.contains("://"), let components = URLComponents(string: value), let host = components.host {
            value = host.lowercased()
        } else {
            if let slash = value.firstIndex(of: "/") {
                value = String(value[..<slash])
            }
            if let query = value.firstIndex(of: "?") {
                value = String(value[..<query])
            }
            if let fragment = value.firstIndex(of: "#") {
                value = String(value[..<fragment])
            }
        }

        if let at = value.lastIndex(of: "@") {
            value = String(value[value.index(after: at)...])
        }
        if let port = value.firstIndex(of: ":") {
            value = String(value[..<port])
        }

        if value.hasPrefix("www.") {
            value = String(value.dropFirst(4))
        }
        if value.hasPrefix("m.") {
            value = String(value.dropFirst(2))
        }

        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        if value.isEmpty || value.contains(" ") || !value.contains(".") {
            return nil
        }
        return value
    }

    private func domainCandidates(for normalizedDomain: String) -> [String] {
        let candidates: [String] = [
            normalizedDomain,
            "www.\(normalizedDomain)",
            "m.\(normalizedDomain)"
        ]
        var deduped: [String] = []
        for domain in candidates where !domain.isEmpty && !deduped.contains(domain) {
            deduped.append(domain)
        }
        return deduped
    }

    private func webDomainToken(from normalizedDomain: String) -> WebDomainToken? {
        for candidate in domainCandidates(for: normalizedDomain) {
            if let token = WebDomain(domain: candidate).token {
                return token
            }
        }
        return nil
    }

    private func webDomainTokens(from domains: [String]) -> Set<WebDomainToken> {
        var tokens = Set<WebDomainToken>()
        for domain in normalizedDomains(domains) {
            if let token = webDomainToken(from: domain) {
                tokens.insert(token)
            }
        }
        return tokens
    }

    private func webDomains(from domains: [String]) -> Set<WebDomain> {
        var resolved = Set<WebDomain>()
        for domain in normalizedDomains(domains) {
            for candidate in domainCandidates(for: domain) {
                resolved.insert(WebDomain(domain: candidate))
            }
        }
        return resolved
    }

    private func webDomains(from tokens: Set<WebDomainToken>) -> Set<WebDomain> {
        var resolved = Set<WebDomain>()
        for token in tokens {
            resolved.insert(WebDomain(token: token))
        }
        return resolved
    }

    private func selfApplicationToken() -> ApplicationToken? {
        guard let bundleId = Bundle.main.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
              !bundleId.isEmpty else {
            return nil
        }
        return Application(bundleIdentifier: bundleId).token
    }

    private func selfExemptApplicationTokens() -> Set<ApplicationToken> {
        guard let token = selfApplicationToken() else {
            return Set<ApplicationToken>()
        }
        return Set([token])
    }

    private func applicationTokens(for bundleIds: Set<String>) -> Set<ApplicationToken> {
        var tokens = Set<ApplicationToken>()
        for raw in bundleIds {
            let bundleId = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !bundleId.isEmpty, let token = Application(bundleIdentifier: bundleId).token else {
                continue
            }
            tokens.insert(token)
        }
        return tokens
    }

    private func ceoAllowedApplicationTokens() -> Set<ApplicationToken> {
        var tokens = selfExemptApplicationTokens()
        tokens.formUnion(applicationTokens(for: ceoAlwaysAllowedBundleIds))
        return tokens
    }

    private func ceoForceBlockedApplicationTokens() -> Set<ApplicationToken> {
        var tokens = applicationTokens(for: ceoForceBlockedBundleIds)
        tokens.subtract(ceoAllowedApplicationTokens())
        return tokens
    }

    private func decodeSelection(encoded: String) -> FamilyActivitySelection? {
        decodeFamilyActivitySelectionPayload(encoded)
    }

    private func encodeSelection(_ selection: FamilyActivitySelection) -> String? {
        guard let data = try? JSONEncoder().encode(selection) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func mergeSelections(encodedPayloads: [String]) -> FamilyActivitySelection {
        var merged = FamilyActivitySelection()
        for payload in encodedPayloads {
            guard let decoded = decodeSelection(encoded: payload) else {
                continue
            }
            merged.applicationTokens.formUnion(decoded.applicationTokens)
            merged.categoryTokens.formUnion(decoded.categoryTokens)
            merged.webDomainTokens.formUnion(decoded.webDomainTokens)
        }
        return merged
    }

    private func storedClassicPayloads() -> [String] {
        sharedDefaults()?.stringArray(forKey: classicSelectionStorageKey) ?? []
    }

    private func storedClassicPausePayloads() -> [String] {
        sharedDefaults()?.stringArray(forKey: classicPauseSelectionStorageKey) ?? []
    }

    private func loadClassicRestPeriods() -> [PlannedClassicRest] {
        guard let defaults = sharedDefaults(),
              let data = defaults.data(forKey: classicRestPeriodsStorageKey),
              let periods = try? JSONDecoder().decode([PlannedClassicRest].self, from: data) else {
            return []
        }
        return periods
    }

    private func loadClassicDailyLimitEntries() -> [ClassicDailyLimitEntry] {
        guard let defaults = sharedDefaults(),
              let data = defaults.data(forKey: classicDailyLimitEntriesStorageKey),
              let entries = try? JSONDecoder().decode([ClassicDailyLimitEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func saveClassicDailyLimitEntries(_ entries: [ClassicDailyLimitEntry]) {
        guard let defaults = sharedDefaults() else { return }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: classicDailyLimitEntriesStorageKey)
        } else {
            defaults.removeObject(forKey: classicDailyLimitEntriesStorageKey)
        }
    }

    private func loadTriggeredClassicDailyLimitIds() -> Set<String> {
        Set(sharedDefaults()?.stringArray(forKey: classicDailyLimitTriggeredIdsStorageKey) ?? [])
    }

    private func saveTriggeredClassicDailyLimitIds(_ ids: Set<String>) {
        sharedDefaults()?.set(Array(ids), forKey: classicDailyLimitTriggeredIdsStorageKey)
    }

    private func payloadsForTriggeredClassicDailyLimits() -> [String] {
        let triggered = loadTriggeredClassicDailyLimitIds()
        guard !triggered.isEmpty else { return [] }
        return loadClassicDailyLimitEntries()
            .filter { triggered.contains($0.id) }
            .map { $0.selector }
    }

    private func saveClassicRestPeriods(_ periods: [PlannedClassicRest]) {
        guard let defaults = sharedDefaults() else { return }
        if let data = try? JSONEncoder().encode(periods) {
            defaults.set(data, forKey: classicRestPeriodsStorageKey)
        } else {
            defaults.removeObject(forKey: classicRestPeriodsStorageKey)
        }
    }

    private func classicPauseActiveNow(at date: Date = Date(), periods: [PlannedClassicRest]? = nil) -> Bool {
        let source = periods ?? loadClassicRestPeriods()
        let nowMillis = Int64(date.timeIntervalSince1970 * 1000.0)
        return source.contains { period in
            period.startMillis <= nowMillis && period.endMillis > nowMillis
        }
    }

    private func persistFocusSelection(_ selection: FamilyActivitySelection) {
        self.selection = selection
        if let encoded = encodeSelection(selection) {
            sharedDefaults()?.set(encoded, forKey: selectionStorageKey)
        }
    }

    private func applyEffectiveShield() {
        guard let defaults = sharedDefaults() else {
            store.clearAllSettings()
            return
        }

        let ceoEnabled = defaults.bool(forKey: ceoEnabledStorageKey)

        let focusEnabled =
            defaults.bool(forKey: focusEnabledStorageKey)
            || defaults.bool(forKey: scheduledFocusEnabledStorageKey)
        let classicEnabled = defaults.bool(forKey: classicEnabledStorageKey)
        let classicPauseEnabled = defaults.bool(forKey: classicPauseEnabledStorageKey)

        var payloads: [String] = []
        if focusEnabled, let payload = defaults.string(forKey: selectionStorageKey), !payload.isEmpty {
            payloads.append(payload)
        }
        if classicEnabled {
            payloads.append(contentsOf: storedClassicPayloads())
        }
        if classicPauseEnabled {
            payloads.append(contentsOf: storedClassicPausePayloads())
        }
        payloads.append(contentsOf: payloadsForTriggeredClassicDailyLimits())

        var merged = mergeSelections(encodedPayloads: payloads)
        var effectiveWebDomains = webDomains(from: merged.webDomainTokens)
        if classicEnabled {
            let classicWebsiteDomains = defaults.stringArray(forKey: classicWebsiteDomainsStorageKey) ?? []
            merged.webDomainTokens.formUnion(
                webDomainTokens(
                    from: classicWebsiteDomains
                )
            )
            effectiveWebDomains.formUnion(webDomains(from: classicWebsiteDomains))
        }
        if classicPauseEnabled {
            let pauseWebsiteDomains = defaults.stringArray(forKey: classicPauseWebsiteDomainsStorageKey) ?? []
            merged.webDomainTokens.formUnion(
                webDomainTokens(
                    from: pauseWebsiteDomains
                )
            )
            effectiveWebDomains.formUnion(webDomains(from: pauseWebsiteDomains))
        }
        effectiveWebDomains.formUnion(webDomains(from: merged.webDomainTokens))
        if let selfToken = selfApplicationToken() {
            merged.applicationTokens.remove(selfToken)
        }

        let hasPayloadSelection = hasSelection(merged)
        let hasWebsiteSelection = !effectiveWebDomains.isEmpty

        if ceoEnabled {
            let ceoAllowedTokens = ceoAllowedApplicationTokens()
            let ceoForcedTokens = ceoForceBlockedApplicationTokens()
            store.shield.applications = ceoForcedTokens.isEmpty ? nil : ceoForcedTokens
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all(
                except: ceoAllowedTokens
            )
            if #available(iOS 16.0, *) {
                store.shield.webDomainCategories = .all(except: Set())
                store.webContent.blockedByFilter = .all(except: Set())
            }
            store.shield.webDomains = nil
            return
        }

        guard hasPayloadSelection || hasWebsiteSelection else {
            store.clearAllSettings()
            return
        }

        store.shield.applications = merged.applicationTokens.isEmpty ? nil : merged.applicationTokens
        store.shield.applicationCategories = merged.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(merged.categoryTokens)
        store.shield.webDomains = merged.webDomainTokens.isEmpty ? nil : merged.webDomainTokens
        if #available(iOS 16.0, *) {
            store.webContent.blockedByFilter = effectiveWebDomains.isEmpty
                ? nil
                : .specific(effectiveWebDomains)
        }
    }

    private func startShield(result: FlutterResult) {
        sharedDefaults()?.set(true, forKey: focusEnabledStorageKey)
        applyEffectiveShield()
        result(nil)
    }
    
    private func stopShield(result: FlutterResult) {
        sharedDefaults()?.set(false, forKey: focusEnabledStorageKey)
        sharedDefaults()?.set(false, forKey: scheduledFocusEnabledStorageKey)
        sharedDefaults()?.set(false, forKey: ceoEnabledStorageKey)
        applyEffectiveShield()
        result(nil)
    }

    private func startCeoShield(result: FlutterResult) {
        sharedDefaults()?.set(true, forKey: ceoEnabledStorageKey)
        applyEffectiveShield()
        result(nil)
    }
    
    private func updateFocusSelection(encodedPayloads: [String], applyShield: Bool) {
        guard !encodedPayloads.isEmpty else {
            if applyShield {
                sharedDefaults()?.set(true, forKey: focusEnabledStorageKey)
                applyEffectiveShield()
            }
            return
        }

        let merged = mergeSelections(encodedPayloads: encodedPayloads)
        persistFocusSelection(merged)
        if applyShield {
            sharedDefaults()?.set(true, forKey: focusEnabledStorageKey)
            applyEffectiveShield()
        }
    }

    private func cacheSelection(args: [String: Any]?, result: FlutterResult) {
        if let packages = args?["packages"] as? [String], !packages.isEmpty {
            updateFocusSelection(encodedPayloads: packages, applyShield: false)
        }
        result(nil)
    }

    private func syncClassicShieldConfig(args: [String: Any]?, result: FlutterResult) {
        let packages = (args?["packages"] as? [String] ?? []).filter { !$0.isEmpty }
        let websites = normalizedDomains(args?["websites"] as? [String] ?? [])
        sharedDefaults()?.set(packages, forKey: classicSelectionStorageKey)
        sharedDefaults()?.set(websites, forKey: classicWebsiteDomainsStorageKey)
        applyEffectiveShield()
        result(nil)
    }

    private func setClassicShieldEnabled(args: [String: Any]?, result: FlutterResult) {
        let enabled = (args?["enabled"] as? Bool) ?? false
        sharedDefaults()?.set(enabled, forKey: classicEnabledStorageKey)
        applyEffectiveShield()
        result(nil)
    }

    private func parseClassicRest(_ raw: [String: Any]) -> PlannedClassicRest? {
        guard let id = raw["id"] as? String else {
            return nil
        }
        let startMillis = (raw["startMillis"] as? NSNumber)?.int64Value
            ?? (raw["startMillis"] as? Int64)
            ?? Int64(raw["startMillis"] as? Int ?? -1)
        let endMillis = (raw["endMillis"] as? NSNumber)?.int64Value
            ?? (raw["endMillis"] as? Int64)
            ?? Int64(raw["endMillis"] as? Int ?? -1)
        guard startMillis > 0, endMillis > startMillis else {
            return nil
        }
        return PlannedClassicRest(id: id, startMillis: startMillis, endMillis: endMillis)
    }

    private func clearClassicRestDeviceActivities() {
        let active = deviceActivityCenter.activities
        let names = active.filter { $0.rawValue.hasPrefix(classicRestActivityPrefix) }
        guard !names.isEmpty else { return }
        deviceActivityCenter.stopMonitoring(Array(names))
    }

    private func startClassicRestDeviceActivity(for rest: PlannedClassicRest, startDate: Date) {
        let endDate = Date(timeIntervalSince1970: TimeInterval(rest.endMillis) / 1000.0)
        guard endDate > startDate else { return }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        do {
            let name = DeviceActivityName("\(classicRestActivityPrefix)\(rest.id)")
            try deviceActivityCenter.startMonitoring(name, during: schedule)
        } catch {
            print("Failed to schedule classic pause for \(rest.id): \(error)")
        }
    }

    private func parseClassicDailyLimitEntry(_ raw: [String: Any]) -> ClassicDailyLimitEntry? {
        guard let id = raw["id"] as? String,
              let selector = (raw["selector"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !selector.isEmpty else {
            return nil
        }
        let kind = ((raw["kind"] as? String) ?? "app").trimmingCharacters(in: .whitespacesAndNewlines)
        let limit = (raw["limitMinutes"] as? NSNumber)?.intValue
            ?? (raw["limitMinutes"] as? Int)
            ?? -1
        guard limit > 0 else { return nil }
        return ClassicDailyLimitEntry(
            id: id,
            selector: selector,
            kind: kind,
            limitMinutes: limit
        )
    }

    private func clearClassicDailyLimitActivities() {
        let active = deviceActivityCenter.activities
        let names = active.filter { $0.rawValue.hasPrefix(classicDailyLimitActivityPrefix) }
        guard !names.isEmpty else { return }
        deviceActivityCenter.stopMonitoring(Array(names))
    }

    private func clearTriggeredClassicDailyLimitIds(except allowedIds: Set<String>) {
        let current = loadTriggeredClassicDailyLimitIds()
        let filtered = current.intersection(allowedIds)
        saveTriggeredClassicDailyLimitIds(filtered)
    }

    private func startClassicDailyLimitMonitoring(for entry: ClassicDailyLimitEntry) {
        guard let selection = decodeSelection(encoded: entry.selector) else { return }
        let hasSelection =
            !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
        guard hasSelection else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let eventName = DeviceActivityEvent.Name("\(classicDailyLimitEventPrefix)\(entry.id)")
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: entry.limitMinutes)
        )

        do {
            let activityName = DeviceActivityName("\(classicDailyLimitActivityPrefix)\(entry.id)")
            try deviceActivityCenter.startMonitoring(activityName, during: schedule, events: [eventName: event])
        } catch {
            print("Failed to schedule classic daily limit for \(entry.id): \(error)")
        }
    }

    private func syncClassicDailyLimits(args: [String: Any]?, result: FlutterResult) {
        let rawEntries = args?["entries"] as? [[String: Any]] ?? []
        let parsed = rawEntries.compactMap(parseClassicDailyLimitEntry)
        saveClassicDailyLimitEntries(parsed)
        clearClassicDailyLimitActivities()
        clearTriggeredClassicDailyLimitIds(except: Set(parsed.map(\.id)))

        for entry in parsed {
            startClassicDailyLimitMonitoring(for: entry)
        }
        applyEffectiveShield()
        result(true)
    }

    private func encodeWebsiteDomainSelection(args: [String: Any]?, result: FlutterResult) {
        guard let rawDomain = args?["domain"] as? String else {
            result(
                FlutterError(
                    code: "INVALID_DOMAIN",
                    message: "A domain string is required.",
                    details: nil
                )
            )
            return
        }
        guard let normalizedDomain = normalizedDomains([rawDomain]).first else {
            result(
                FlutterError(
                    code: "INVALID_DOMAIN",
                    message: "Provide a valid domain such as youtube.com.",
                    details: nil
                )
            )
            return
        }
        guard let token = webDomainToken(from: normalizedDomain) else {
            result(
                FlutterError(
                    code: "DOMAIN_TOKEN_UNAVAILABLE",
                    message: "This domain cannot be converted to a Screen Time token on this device.",
                    details: nil
                )
            )
            return
        }
        var selection = FamilyActivitySelection()
        selection.webDomainTokens = Set([token])
        guard let encoded = encodeSelection(selection) else {
            result(
                FlutterError(
                    code: "ENCODE_ERROR",
                    message: "Failed to encode website selection.",
                    details: nil
                )
            )
            return
        }
        result(encoded)
    }

    private func encodeApplicationBundleSelection(args: [String: Any]?, result: FlutterResult) {
        guard let bundleIdentifier = (args?["bundleIdentifier"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !bundleIdentifier.isEmpty else {
            result(
                FlutterError(
                    code: "INVALID_BUNDLE_ID",
                    message: "A bundle identifier is required.",
                    details: nil
                )
            )
            return
        }
        guard let token = Application(bundleIdentifier: bundleIdentifier).token else {
            result(
                FlutterError(
                    code: "APP_TOKEN_UNAVAILABLE",
                    message: "This app cannot be converted to a Screen Time token on this iPhone.",
                    details: nil
                )
            )
            return
        }
        var selection = FamilyActivitySelection()
        selection.applicationTokens = Set([token])
        guard let encoded = encodeSelection(selection) else {
            result(
                FlutterError(
                    code: "ENCODE_ERROR",
                    message: "Failed to encode app selection.",
                    details: nil
                )
            )
            return
        }
        result(encoded)
    }

    private func describeAppSelectionPayload(args: [String: Any]?, result: @escaping FlutterResult) {
        guard let payload = (args?["payload"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !payload.isEmpty else {
            result(nil)
            return
        }
        guard let selection = decodeSelection(encoded: payload),
              let token = selection.applicationTokens.first else {
            result(nil)
            return
        }
        let app = Application(token: token)
        let bundleIdentifier = app.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let directName = app.localizedDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let directName, !directName.isEmpty {
            result(["appName": directName, "bundleIdentifier": bundleIdentifier])
            return
        }
        // `localizedDisplayName` is almost always nil for picked tokens. Render
        // the system `Label(token)` off-screen and read the resolved name from
        // the UILabel SwiftUI produces — this gives the real name as plain text
        // so the header can render it without any PlatformView/Apple capsule.
        Self.resolveTokenDisplayName(label: Label(token).labelStyle(.titleOnly)) { name in
            result(["appName": name ?? "", "bundleIdentifier": bundleIdentifier])
        }
    }

    private func describeWebsiteSelectionPayload(args: [String: Any]?, result: @escaping FlutterResult) {
        guard let payload = (args?["payload"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !payload.isEmpty else {
            result(nil)
            return
        }
        guard let selection = decodeSelection(encoded: payload),
              let token = selection.webDomainTokens.first else {
            result(nil)
            return
        }
        let directDomain = WebDomain(token: token).domain?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let directDomain, !directDomain.isEmpty {
            result(["domain": directDomain])
            return
        }
        Self.resolveTokenDisplayName(label: Label(token).labelStyle(.titleOnly)) { name in
            result(["domain": name ?? ""])
        }
    }

    /// Renders a Family Controls `Label(token)` off-screen and extracts the
    /// resolved display name from the `UILabel` SwiftUI produces. The name
    /// usually resolves asynchronously on first render, so we retry once after
    /// a short delay before giving up.
    private static func resolveTokenDisplayName<L: View>(label: L, completion: @escaping (String?) -> Void) {
        let host = UIHostingController(rootView: label.fixedSize())
        host.view.frame = CGRect(x: -10_000, y: -10_000, width: 400, height: 80)
        host.view.backgroundColor = .clear
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
            .first
            ?? UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.windows.first }
                .first
        window?.addSubview(host.view)

        // Family Controls resolves the token name asynchronously on first
        // render, so poll a few times before giving up.
        let delays: [Double] = [0.0, 0.35, 0.8, 1.4]
        func attempt(_ index: Int) {
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            if let name = firstResolvedName(in: host.view) {
                host.view.removeFromSuperview()
                completion(name)
                return
            }
            if index + 1 < delays.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + (delays[index + 1] - delays[index])) {
                    attempt(index + 1)
                }
            } else {
                host.view.removeFromSuperview()
                completion(nil)
            }
        }
        attempt(0)
    }

    /// SwiftUI renders Family Controls token names without a plain `UILabel`,
    /// but it sets the accessibility label of the rendered view to the resolved
    /// name (for VoiceOver). We read a `UILabel`'s text when present, otherwise
    /// fall back to the first non-empty `accessibilityLabel` in the hierarchy.
    private static func firstResolvedName(in view: UIView) -> String? {
        if let label = view as? UILabel,
           let text = label.text?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return text
        }
        if let a11y = view.accessibilityLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
           !a11y.isEmpty {
            return a11y
        }
        for sub in view.subviews {
            if let found = firstResolvedName(in: sub) { return found }
        }
        return nil
    }

    private func syncClassicPauseSchedule(args: [String: Any]?, result: FlutterResult) {
        let payloads = (args?["packages"] as? [String] ?? []).filter { !$0.isEmpty }
        let rawPeriods = args?["periods"] as? [[String: Any]] ?? []
        let websites = normalizedDomains(args?["websites"] as? [String] ?? [])
        let parsed = rawPeriods.compactMap(parseClassicRest)
        sharedDefaults()?.set(payloads, forKey: classicPauseSelectionStorageKey)
        sharedDefaults()?.set(websites, forKey: classicPauseWebsiteDomainsStorageKey)
        saveClassicRestPeriods(parsed)
        clearClassicRestDeviceActivities()

        let now = Date()
        let pauseEnabled = !payloads.isEmpty && classicPauseActiveNow(at: now, periods: parsed)
        sharedDefaults()?.set(pauseEnabled, forKey: classicPauseEnabledStorageKey)
        applyEffectiveShield()

        for rest in parsed {
            let endDate = Date(timeIntervalSince1970: TimeInterval(rest.endMillis) / 1000.0)
            guard endDate > now else { continue }
            let requestedStart = Date(timeIntervalSince1970: TimeInterval(rest.startMillis) / 1000.0)
            let effectiveStart = requestedStart > now ? requestedStart : now
            startClassicRestDeviceActivity(for: rest, startDate: effectiveStart)
        }

        result(true)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        
        switch call.method {
        case "requestPermissions":
            requestPermissions(result: result)
        case "isAuthorized":
            result(center.authorizationStatus == .approved)
        case "getAuthorizationStatus":
            result(authorizationStatusCode())
        case "supportsPrivateScreenTimeSummaryView":
            #if targetEnvironment(simulator)
            result("simulator")
            #else
            if center.authorizationStatus != .approved {
                result("authorization_required")
            } else if #available(iOS 16.0, *) {
                result("available")
            } else {
                result("unsupported")
            }
            #endif
        case "startShield":
            if let packages = args?["packages"] as? [String], !packages.isEmpty {
                updateFocusSelection(encodedPayloads: packages, applyShield: true)
                result(nil)
            } else {
                startShield(result: result)
            }
        case "cacheSelection":
            cacheSelection(args: args, result: result)
        case "syncClassicShieldConfig":
            syncClassicShieldConfig(args: args, result: result)
        case "setClassicShieldEnabled":
            setClassicShieldEnabled(args: args, result: result)
        case "syncClassicPauseSchedule":
            syncClassicPauseSchedule(args: args, result: result)
        case "encodeWebsiteDomainSelection":
            encodeWebsiteDomainSelection(args: args, result: result)
        case "encodeApplicationBundleSelection":
            encodeApplicationBundleSelection(args: args, result: result)
        case "describeAppSelectionPayload":
            describeAppSelectionPayload(args: args, result: result)
        case "describeWebsiteSelectionPayload":
            describeWebsiteSelectionPayload(args: args, result: result)
        case "syncClassicDailyLimits":
            syncClassicDailyLimits(args: args, result: result)
        case "startCeoShield":
            startCeoShield(result: result)
        case "stopShield":
            stopShield(result: result)
        case "isShieldActive":
            let defaults = sharedDefaults()
            let active =
                (defaults?.bool(forKey: focusEnabledStorageKey) ?? false)
                || (defaults?.bool(forKey: scheduledFocusEnabledStorageKey) ?? false)
                || (defaults?.bool(forKey: classicEnabledStorageKey) ?? false)
                || (defaults?.bool(forKey: classicPauseEnabledStorageKey) ?? false)
                || !(defaults?.stringArray(forKey: classicDailyLimitTriggeredIdsStorageKey)?.isEmpty ?? true)
                || (defaults?.bool(forKey: ceoEnabledStorageKey) ?? false)
            result(active)
        case "openFamilyActivityPicker":
            presentFamilyActivityPicker(result: result)
        case "openFamilyActivityWebsitePicker":
            presentFamilyActivityPicker(result: result, requiresWebDomains: true)
        case "openSystemSettings":
            DispatchQueue.main.async {
                guard let url = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(url) else {
                    result(false)
                    return
                }
                UIApplication.shared.open(url, options: [:]) { opened in
                    result(opened)
                }
            }
        case "syncScreenTimeTheme":
            if let tokens = args?["tokens"] as? [String: String] {
                saveScreenTimeTheme(tokens: tokens)
            }
            result(true)
        case "syncPlannedSessions":
            syncPlannedSessions(args: args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func presentFamilyActivityPicker(
        result: @escaping FlutterResult,
        requiresWebDomains: Bool = false
    ) {
        DispatchQueue.main.async {
            guard #available(iOS 16.0, *) else {
                result(FlutterError(
                    code: "UNSUPPORTED_OS",
                    message: "Family Controls requires iOS 16 or later.",
                    details: nil
                ))
                return
            }
            guard self.center.authorizationStatus == .approved else {
                result(FlutterError(
                    code: "NOT_AUTHORIZED",
                    message: "Screen Time access is required before selecting apps or websites.",
                    details: nil
                ))
                return
            }
            guard self.hasAppGroupAccess() else {
                result(FlutterError(
                    code: "APP_GROUP_MISSING",
                    message: "App Group access is not available in this build. Check signing & capabilities.",
                    details: nil
                ))
                return
            }
            guard self.activePickerResult == nil else {
                result(FlutterError(
                    code: "PICKER_IN_FLIGHT",
                    message: "The Apple picker is already presented.",
                    details: nil
                ))
                return
            }
            guard let rootVC = self.topViewController() else {
                result(FlutterError(code: "NO_ROOT_VC", message: "No root view controller", details: nil))
                return
            }

            self.activePickerResult = result
            self.activePickerRequiresWebDomains = requiresWebDomains

            let pickerWrapper = PickerWrapperView(
                selection: FamilyActivitySelection(),
                title: requiresWebDomains ? "Select Websites" : "Select Distractions",
                subtitle: requiresWebDomains
                    ? "Choose at least one website to block."
                    : nil,
                onComplete: { newSelection in
                    self.selection = newSelection
                    self.finishPicker(with: newSelection)
                },
                onCancel: {
                    self.finishPicker(with: nil)
                }
            )

            let hostingController = UIHostingController(rootView: pickerWrapper)
            hostingController.modalPresentationStyle = .pageSheet
            let delegate = PickerPresentationDelegate { [weak self] in
                self?.finishPicker(with: nil)
            }
            hostingController.presentationController?.delegate = delegate
            self.activePickerDelegate = delegate
            self.activePickerHost = hostingController
            rootVC.present(hostingController, animated: true)
        }
    }
}

@available(iOS 16.0, *)
private struct NativeBlockedWebsiteTokenLabelView: View {
    let token: WebDomainToken
    let textColor: UIColor?
    let isDarkTheme: Bool
    let showIcon: Bool

    var body: some View {
        Group {
            if showIcon {
                Label(token).labelStyle(.titleAndIcon)
            } else {
                Label(token).labelStyle(.titleOnly)
            }
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(textColor.map { Color(uiColor: $0) } ?? .primary)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
        .environment(\.colorScheme, isDarkTheme ? .dark : .light)
    }
}

@available(iOS 16.0, *)
private final class BlockedWebsiteTokenLabelPlatformView: NSObject, FlutterPlatformView {
    private let container: UIView

    init(frame: CGRect, viewId: Int64, args: Any?) {
        container = UIView(frame: frame)
        container.backgroundColor = .clear
        container.isOpaque = false
        super.init()

        let arguments = args as? [String: Any]
        let payload = (arguments?["payload"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fallbackTitle = (arguments?["fallbackTitle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Blocked website"
        let textColorHex = (arguments?["textColorHex"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let textColor = (textColorHex?.isEmpty == false) ? UIColor(hexString: textColorHex!) : nil
        let isDarkTheme = (arguments?["isDarkTheme"] as? Bool) ?? true
        let showIcon = (arguments?["showIcon"] as? Bool) ?? true

        if let token = Self.decodeWebsiteToken(from: payload) {
            let host = UIHostingController(
                rootView: NativeBlockedWebsiteTokenLabelView(
                    token: token,
                    textColor: textColor,
                    isDarkTheme: isDarkTheme,
                    showIcon: showIcon
                )
            )
            host.view.backgroundColor = .clear
            host.view.isOpaque = false
            host.view.overrideUserInterfaceStyle = isDarkTheme ? .dark : .light
            host.overrideUserInterfaceStyle = isDarkTheme ? .dark : .light
            host.sizingOptions = [.intrinsicContentSize]
            host.view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(host.view)
            // Size the hosting view to its text height and center it, instead
            // of stretching it to fill the container. Stretching left an empty
            // band that the hosting UIView tinted gray onto the card border
            // below; centering keeps the empty space inside the `.clear`
            // container so no gray artifact bleeds out.
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                host.view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ])
            // iOS resets UIHostingController.view.backgroundColor to the system
            // color once the view enters the hierarchy, redrawing a dark gray
            // rectangle that the `.clear` set above does not survive. Re-clear
            // it (and the container) on the next runloop tick.
            let hostView: UIView = host.view
            let containerView = container
            DispatchQueue.main.async {
                hostView.backgroundColor = .clear
                hostView.isOpaque = false
                containerView.backgroundColor = .clear
            }
        } else {
            let label = UILabel(frame: frame)
            label.text = fallbackTitle
            label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            label.textColor = textColor ?? .label
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                label.topAnchor.constraint(equalTo: container.topAnchor),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }
    }

    func view() -> UIView {
        container
    }

    static func decodeWebsiteToken(from payload: String) -> WebDomainToken? {
        guard let selection = decodeFamilyActivitySelectionPayload(payload) else { return nil }
        return selection.webDomainTokens.first
    }
}

@available(iOS 16.0, *)
private final class BlockedWebsiteTokenIconPlatformView: NSObject, FlutterPlatformView {
    private let container: UIView

    init(frame: CGRect, viewId: Int64, args: Any?) {
        container = UIView(frame: frame)
        container.backgroundColor = .clear
        super.init()

        let arguments = args as? [String: Any]
        let payload = (arguments?["payload"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isDarkTheme = (arguments?["isDarkTheme"] as? Bool) ?? true

        if let token = BlockedWebsiteTokenLabelPlatformView.decodeWebsiteToken(from: payload) {
            let host = UIHostingController(
                rootView: NativeBlockedWebsiteTokenIconView(token: token)
            )
            host.view.backgroundColor = .clear
            host.overrideUserInterfaceStyle = isDarkTheme ? .dark : .light
            host.view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: container.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }
    }

    func view() -> UIView {
        container
    }
}

@available(iOS 16.0, *)
private final class BlockedWebsiteTokenLabelPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        BlockedWebsiteTokenLabelPlatformView(frame: frame, viewId: viewId, args: args)
    }
}

@available(iOS 16.0, *)
private final class BlockedWebsiteTokenIconPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        BlockedWebsiteTokenIconPlatformView(frame: frame, viewId: viewId, args: args)
    }
}

@available(iOS 16.0, *)
struct PickerWrapperView: View {
    @State var selection: FamilyActivitySelection
    var title: String
    var subtitle: String?
    var onComplete: (FamilyActivitySelection) -> Void
    var onCancel: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 6)
                }
                FamilyActivityPicker(selection: $selection)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onComplete(selection)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

private final class PickerPresentationDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss()
    }
}

@available(iOS 16.0, *)
private extension DeviceActivityReport.Context {
    static let ceoosDailyScreenTime = Self("WakeApp Daily Screen Time")
    static let ceoosWeeklyAverageScreenTime = Self("WakeApp Weekly Average Screen Time")
}

@available(iOS 16.0, *)
private final class BlockedAppTokenLabelPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        BlockedAppTokenLabelPlatformView(frame: frame, viewId: viewId, args: args)
    }
}

@available(iOS 16.0, *)
private final class BlockedAppTokenLabelPlatformView: NSObject, FlutterPlatformView {
    private let container: UIView

    init(frame: CGRect, viewId: Int64, args: Any?) {
        container = UIView(frame: frame)
        container.backgroundColor = .clear
        container.isOpaque = false
        super.init()

        let arguments = args as? [String: Any]
        let payload = (arguments?["payload"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fallbackTitle = (arguments?["fallbackTitle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Blocked app"
        let textColorHex = (arguments?["textColorHex"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let textColor = (textColorHex?.isEmpty == false) ? UIColor(hexString: textColorHex!) : nil
        let isDarkTheme = (arguments?["isDarkTheme"] as? Bool) ?? true
        let showIcon = (arguments?["showIcon"] as? Bool) ?? true

        if let token = Self.decodeApplicationToken(from: payload) {
            let host = UIHostingController(
                rootView: NativeBlockedAppTokenLabelView(
                    token: token,
                    textColor: textColor,
                    isDarkTheme: isDarkTheme,
                    showIcon: showIcon
                )
            )
            host.view.backgroundColor = .clear
            host.view.isOpaque = false
            host.view.overrideUserInterfaceStyle = isDarkTheme ? .dark : .light
            host.overrideUserInterfaceStyle = isDarkTheme ? .dark : .light
            host.sizingOptions = [.intrinsicContentSize]
            host.view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(host.view)
            // Size the hosting view to its text height and center it, instead
            // of stretching it to fill the container. Stretching left an empty
            // band that the hosting UIView tinted gray onto the card border
            // below; centering keeps the empty space inside the `.clear`
            // container so no gray artifact bleeds out.
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                host.view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ])
            // iOS resets UIHostingController.view.backgroundColor to the system
            // color once the view enters the hierarchy, redrawing a dark gray
            // rectangle that the `.clear` set above does not survive. Re-clear
            // it (and the container) on the next runloop tick.
            let hostView: UIView = host.view
            let containerView = container
            DispatchQueue.main.async {
                hostView.backgroundColor = .clear
                hostView.isOpaque = false
                containerView.backgroundColor = .clear
            }
        } else {
            let label = UILabel(frame: frame)
            label.text = fallbackTitle
            label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            label.textColor = textColor ?? .label
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                label.topAnchor.constraint(equalTo: container.topAnchor),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }
    }

    func view() -> UIView {
        container
    }

    static func decodeApplicationToken(from payload: String) -> ApplicationToken? {
        guard let selection = decodeFamilyActivitySelectionPayload(payload) else { return nil }
        return selection.applicationTokens.first
    }
}

@available(iOS 16.0, *)
private struct NativeBlockedAppTokenLabelView: View {
    let token: ApplicationToken
    let textColor: UIColor?
    let isDarkTheme: Bool
    let showIcon: Bool

    var body: some View {
        Group {
            if showIcon {
                Label(token).labelStyle(.titleAndIcon)
            } else {
                // Title-only: Apple's `Label(token)` with `.titleOnly`
                // resolves the real app name through Family Controls, but
                // skips rendering the icon — which is the source of the
                // residual gray rectangle/placeholder the user reported in
                // the ManageBlockedItemSheet header.
                Label(token).labelStyle(.titleOnly)
            }
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(textColor.map { Color(uiColor: $0) } ?? .primary)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
        .environment(\.colorScheme, isDarkTheme ? .dark : .light)
    }
}

@available(iOS 16.0, *)
private final class PrivateScreenTimeSummaryPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        PrivateScreenTimeSummaryPlatformView(frame: frame)
    }
}

@available(iOS 16.0, *)
private final class PrivateScreenTimeSummaryPlatformView: NSObject, FlutterPlatformView {
    private let containerView = UIView()
    private let hostingController = UIHostingController(rootView: PrivateScreenTimeSummaryView())

    init(frame: CGRect) {
        super.init()
        containerView.frame = frame
        containerView.backgroundColor = .clear

        let hostedView = hostingController.view!
        hostedView.backgroundColor = .clear
        hostedView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    func view() -> UIView {
        containerView
    }
}

@available(iOS 16.0, *)
private struct PrivateScreenTimeSummaryView: View {
    private var todayFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .hourly(
                during: DateInterval(
                    start: Calendar.current.startOfDay(for: .now),
                    end: .now
                )
            ),
            users: .all,
            devices: .all
        )
    }

    private var weeklyAverageFilter: DeviceActivityFilter {
        let endDate = Date()
        let startDate =
            Calendar.current.date(
                byAdding: .day,
                value: -6,
                to: Calendar.current.startOfDay(for: endDate)
            ) ?? Calendar.current.startOfDay(for: endDate)

        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: startDate, end: endDate)),
            users: .all,
            devices: .all
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            if AuthorizationCenter.shared.authorizationStatus == .approved {
                DeviceActivityReport(
                    .ceoosDailyScreenTime,
                    filter: todayFilter
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                DeviceActivityReport(
                    .ceoosWeeklyAverageScreenTime,
                    filter: weeklyAverageFilter
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PrivateScreenTimeFallbackCard(
                    title: "TODAY",
                    subtitle: "grant access"
                )
                PrivateScreenTimeFallbackCard(
                    title: "7D AVG",
                    subtitle: "grant access"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

@available(iOS 16.0, *)
private struct PrivateScreenTimeFallbackCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        let cardBackground = screenTimeThemeColor("card_bg", fallback: Color(red: 0.13, green: 0.15, blue: 0.18))
        let cardBorder = screenTimeThemeColor("card_border", fallback: Color.white.opacity(0.08))
        let titleColor = screenTimeThemeColor("title", fallback: Color.white.opacity(0.48))
        let valueColor = screenTimeThemeColor("value", fallback: Color.white.opacity(0.96))
        let subtitleColor = screenTimeThemeColor("subtitle", fallback: Color.white.opacity(0.55))

        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackground)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(titleColor)
                    .tracking(2)
                Spacer(minLength: 8)
                Text("--")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                Spacer(minLength: 6)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(subtitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private let screenTimeThemeAppGroupId = "group.com.wakeapp.ceoos"
private let screenTimeThemeKeyPrefix = "screen_time_theme_"

private func screenTimeThemeDefaults() -> UserDefaults? {
    guard FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: screenTimeThemeAppGroupId
    ) != nil else {
        return nil
    }
    return UserDefaults(suiteName: screenTimeThemeAppGroupId)
}

private func screenTimeThemeColor(_ key: String, fallback: Color) -> Color {
    guard let defaults = screenTimeThemeDefaults(),
          let raw = defaults.string(forKey: "screen_time_theme_\(key)"),
          let uiColor = UIColor(hexString: raw) else {
        return fallback
    }
    return Color(uiColor)
}

private extension UIColor {
    convenience init?(hexString: String) {
        var cleaned = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 8, let value = UInt64(cleaned, radix: 16) else {
            return nil
        }
        let a = CGFloat((value & 0xFF000000) >> 24) / 255.0
        let r = CGFloat((value & 0x00FF0000) >> 16) / 255.0
        let g = CGFloat((value & 0x0000FF00) >> 8) / 255.0
        let b = CGFloat(value & 0x000000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static var flutterTouchRateNoopBlock: AnyObject?
  private static var flutterDisplayRefreshRateBlock: AnyObject?
  private var didInstallFlutterVSyncCrashWorkaround = false

  private func installDisplayRefreshRateFallbackIfNeeded() -> Bool {
    guard let displayLinkManagerClass = NSClassFromString("DisplayLinkManager") else {
      NSLog("[iOS26-VSync] DisplayLinkManager class not found; cannot install fallback")
      return false
    }

    let selector = NSSelectorFromString("displayRefreshRate")
    guard let targetMethod = class_getClassMethod(displayLinkManagerClass, selector) else {
      NSLog("[iOS26-VSync] displayRefreshRate method not found; cannot install fallback")
      return false
    }

    let force60HzBlock: @convention(block) (AnyObject) -> Double = { _ in
      return 60.0
    }
    let blockObject = unsafeBitCast(force60HzBlock, to: AnyObject.self)
    Self.flutterDisplayRefreshRateBlock = blockObject
    let forcedIMP = imp_implementationWithBlock(blockObject)
    method_setImplementation(targetMethod, forcedIMP)
    NSLog("[iOS26-VSync] installed displayRefreshRate fallback (60Hz)")
    return true
  }

  private static func isRunningInTestFlight() -> Bool {
    #if targetEnvironment(simulator)
    // Simulator uses a sandbox receipt; treat as TestFlight-like for dev.
    return true
    #else
    guard let receiptUrl = Bundle.main.appStoreReceiptURL else { return false }
    return receiptUrl.lastPathComponent == "sandboxReceipt"
    #endif
  }

  private func installFlutterIOS26VSyncCrashWorkaroundIfNeeded() {
    guard #available(iOS 26.0, *) else { return }
    guard !didInstallFlutterVSyncCrashWorkaround else { return }

    guard let flutterViewControllerClass = NSClassFromString("FlutterViewController") else {
      NSLog("[iOS26-VSync] FlutterViewController class not found; skip workaround")
      return
    }

    let selector = NSSelectorFromString("createTouchRateCorrectionVSyncClientIfNeeded")
    guard let targetMethod = class_getInstanceMethod(flutterViewControllerClass, selector) else {
      NSLog("[iOS26-VSync] target method missing; trying displayRefreshRate fallback")
      didInstallFlutterVSyncCrashWorkaround = installDisplayRefreshRateFallbackIfNeeded()
      return
    }

    let noopBlock: @convention(block) (AnyObject) -> Void = { _ in
      // Intentionally no-op on iOS 26+ to avoid Flutter VSyncClient startup crash.
    }
    let blockObject = unsafeBitCast(noopBlock, to: AnyObject.self)
    Self.flutterTouchRateNoopBlock = blockObject
    let noopIMP = imp_implementationWithBlock(blockObject)
    method_setImplementation(targetMethod, noopIMP)

    didInstallFlutterVSyncCrashWorkaround = true
    NSLog("[iOS26-VSync] installed touch-rate correction workaround")
  }

  private func registerPlugin(_ name: String, action: (FlutterPluginRegistrar) -> Void) {
    guard let registrar = self.registrar(forPlugin: name) else {
      NSLog("[PluginReg] registrar missing: \(name)")
      return
    }
    NSLog("[PluginReg] -> \(name)")
    action(registrar)
    NSLog("[PluginReg] <- \(name)")
  }

  private func registerPluginsDeterministically() {
    NSLog("[PluginReg] deterministic registration start")
    NSLog("[PluginReg] os=\(UIDevice.current.systemVersion)")

    #if canImport(adaptive_platform_ui)
    registerPlugin("AdaptivePlatformUiPlugin") { AdaptivePlatformUiPlugin.register(with: $0) }
    #endif
    #if canImport(app_links)
    registerPlugin("AppLinksIosPlugin") { AppLinksIosPlugin.register(with: $0) }
    #endif
    #if canImport(flutter_local_notifications)
    registerPlugin("FlutterLocalNotificationsPlugin") { FlutterLocalNotificationsPlugin.register(with: $0) }
    #endif
    #if canImport(google_sign_in_ios)
    registerPlugin("FLTGoogleSignInPlugin") { FLTGoogleSignInPlugin.register(with: $0) }
    #endif
    #if canImport(home_widget)
    registerPlugin("HomeWidgetPlugin") { HomeWidgetPlugin.register(with: $0) }
    #endif
    #if canImport(image_picker_ios)
    registerPlugin("FLTImagePickerPlugin") { FLTImagePickerPlugin.register(with: $0) }
    #endif
    #if canImport(path_provider_foundation)
    registerPlugin("PathProviderPlugin") { PathProviderPlugin.register(with: $0) }
    #endif
    #if canImport(purchases_flutter)
    registerPlugin("PurchasesFlutterPlugin") { PurchasesFlutterPlugin.register(with: $0) }
    #endif
    #if canImport(shared_preferences_foundation)
    registerPlugin("SharedPreferencesPlugin") { SharedPreferencesPlugin.register(with: $0) }
    #endif

    // Sign in with Apple and url_launcher only respond to method calls (no
    // startup work), so they are safe to register on iOS 26+ — and REQUIRED:
    // without them, Sign in with Apple and "Manage subscription" throw
    // MissingPluginException. Only Workmanager is skipped on iOS 26 below.
    #if canImport(sign_in_with_apple)
    registerPlugin("SignInWithApplePlugin") { SignInWithApplePlugin.register(with: $0) }
    #endif
    #if canImport(url_launcher_ios)
    registerPlugin("URLLauncherPlugin") { URLLauncherPlugin.register(with: $0) }
    #endif

    if #available(iOS 26.0, *) {
      NSLog("[PluginReg] SKIP WorkmanagerPlugin on iOS 26+ (startup crash mitigation)")
    } else {
      #if canImport(workmanager_apple)
      registerPlugin("WorkmanagerPlugin") { WorkmanagerPlugin.register(with: $0) }
      #endif
    }
    NSLog("[PluginReg] deterministic registration end")
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    print("WakeApp Native Launching...")
    installFlutterIOS26VSyncCrashWorkaroundIfNeeded()
    if #available(iOS 26.0, *) {
      registerPluginsDeterministically()
    } else {
      GeneratedPluginRegistrant.register(with: self)
    }
    let didLaunch = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    UNUserNotificationCenter.current().delegate = self
    
    // Robust registration using the plugin registrar
    guard let registrar = self.registrar(forPlugin: "FocusEngine") else {
      NSLog("[FocusEngine] Registrar unavailable at launch; skipping native channel bootstrap.")
      return didLaunch
    }
    let focusChannel = FlutterMethodChannel(name: "com.ceoos.app/focus",
                                              binaryMessenger: registrar.messenger())
    let appEnvChannel = FlutterMethodChannel(
        name: "com.ceoos.app/app_env",
        binaryMessenger: registrar.messenger()
    )
    appEnvChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "isTestFlight":
            result(AppDelegate.isRunningInTestFlight())
        default:
            result(FlutterMethodNotImplemented)
        }
    })
    
    if #available(iOS 15.0, *) {
        focusChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            FocusEngine.shared.handle(call, result: result)
        })
    } else {
        focusChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 15.0+ required", details: nil))
        })
    }

    #if !targetEnvironment(simulator)
    if #available(iOS 16.0, *) {
        registrar.register(
            PrivateScreenTimeSummaryPlatformViewFactory(),
            withId: "com.ceoos.app/private_screen_time_summary"
        )
    }
    #endif
    if #available(iOS 16.0, *) {
        registrar.register(
            BlockedAppTokenLabelPlatformViewFactory(),
            withId: "com.ceoos.app/blocked_app_token_label"
        )
        registrar.register(
            BlockedAppTokenIconPlatformViewFactory(),
            withId: "com.ceoos.app/blocked_app_token_icon"
        )
        registrar.register(
            BlockedWebsiteTokenLabelPlatformViewFactory(),
            withId: "com.ceoos.app/blocked_website_token_label"
        )
        registrar.register(
            BlockedWebsiteTokenIconPlatformViewFactory(),
            withId: "com.ceoos.app/blocked_website_token_icon"
        )
    }

    return didLaunch
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 15.0, *) {
      FocusEngine.shared.handlePlannedNotification(notification.request.content.userInfo)
    }
    completionHandler([.banner, .sound, .list])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if #available(iOS 15.0, *) {
      FocusEngine.shared.handlePlannedNotification(response.notification.request.content.userInfo)
    }
    completionHandler()
  }
}
