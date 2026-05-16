import SwiftUI
import Foundation
import UIKit
import Foundation
import UIKit
import Foundation
import UIKit
import Foundation
import UIKit

struct ScreenTimeMetricConfiguration {
    let title: String
    let value: String
    let subtitle: String
}

enum ScreenTimeMetricFormatter {
    static func string(from duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int(duration.rounded() / 60.0))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(String(format: "%02d", minutes))m"
    }
}

struct ScreenTimeMetricView: View {
    let metric: ScreenTimeMetricConfiguration

    var body: some View {
        let theme = ScreenTimeTheme.current()
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.cardBackground)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.cardBorder, lineWidth: 1)
            VStack(alignment: .leading, spacing: 0) {
                Text(metric.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.titleColor)
                    .tracking(2)
                Spacer(minLength: 8)
                Text(metric.value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Spacer(minLength: 6)
                Text(metric.subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.subtitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
        }
    }
}

private struct ScreenTimeTheme {
    let cardBackground: Color
    let cardBorder: Color
    let titleColor: Color
    let valueColor: Color
    let subtitleColor: Color

    static func current() -> ScreenTimeTheme {
        let fallback = ScreenTimeTheme(
            cardBackground: Color(red: 0.13, green: 0.15, blue: 0.18),
            cardBorder: Color.white.opacity(0.08),
            titleColor: Color.white.opacity(0.48),
            valueColor: Color.white.opacity(0.96),
            subtitleColor: Color.white.opacity(0.55)
        )
        guard let defaults = appGroupDefaults() else {
            return fallback
        }
        return ScreenTimeTheme(
            cardBackground: ScreenTimeTheme.color(from: defaults, key: "card_bg") ?? fallback.cardBackground,
            cardBorder: ScreenTimeTheme.color(from: defaults, key: "card_border") ?? fallback.cardBorder,
            titleColor: ScreenTimeTheme.color(from: defaults, key: "title") ?? fallback.titleColor,
            valueColor: ScreenTimeTheme.color(from: defaults, key: "value") ?? fallback.valueColor,
            subtitleColor: ScreenTimeTheme.color(from: defaults, key: "subtitle") ?? fallback.subtitleColor
        )
    }

    private static func color(from defaults: UserDefaults, key: String) -> Color? {
        let fullKey = "screen_time_theme_\(key)"
        guard let raw = defaults.string(forKey: fullKey),
              let uiColor = UIColor(hexString: raw) else {
            return nil
        }
        return Color(uiColor)
    }
}

private func appGroupDefaults() -> UserDefaults? {
    let appGroupId = "group.com.wakeapp.ceoos"
    guard FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupId
    ) != nil else {
        return nil
    }
    return UserDefaults(suiteName: appGroupId)
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
