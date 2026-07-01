// ShieldConfigurationExtension.swift
//
// Customises the system-rendered shield that iOS shows when the user tries
// to open an app or website blocked by WakeApp. We override every entry
// point of `ShieldConfigurationDataSource` so the shield matches the brand
// (orange WakeApp accent, hourglass icon) and gives the user a clear way
// to either step back or request 5 more minutes (the latter handled by
// `ShieldActionExtension`).
//
// IMPORTANT: this extension only renders the shield. The button taps are
// captured by `ShieldActionExtension.swift` — do not put logic here.

import ManagedSettings
import ManagedSettingsUI
import UIKit

@available(iOS 16.0, *)
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - Application shields

    override func configuration(shielding application: Application)
        -> ShieldConfiguration
    {
        Self.makeShield(
            title: "Time's up",
            subtitle: shieldSubtitleForApp(application)
        )
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        Self.makeShield(
            title: "Time's up",
            subtitle: shieldSubtitleForApp(application)
        )
    }

    // MARK: - Website shields

    override func configuration(shielding webDomain: WebDomain)
        -> ShieldConfiguration
    {
        Self.makeShield(
            title: "Blocked site",
            subtitle: shieldSubtitleForWeb(webDomain)
        )
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        Self.makeShield(
            title: "Blocked site",
            subtitle: shieldSubtitleForWeb(webDomain)
        )
    }

    // MARK: - Helpers

    private func shieldSubtitleForApp(_ application: Application) -> String {
        let name = application.localizedDisplayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty {
            return "“\(name)” reached today's WakeApp limit. Take a breath, then choose."
        }
        return "This app reached today's WakeApp limit. Take a breath, then choose."
    }

    private func shieldSubtitleForWeb(_ webDomain: WebDomain) -> String {
        let domain = webDomain.domain?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let domain, !domain.isEmpty {
            return "“\(domain)” is on your WakeApp block list. Step away, or earn 5 more minutes."
        }
        return "This website is on your WakeApp block list. Step away, or earn 5 more minutes."
    }

    /// Shared brand configuration. The two button labels here must stay in
    /// sync with the cases in `ShieldActionExtension.handle(action:for:…)`:
    /// primary = "Get 5 more minutes", secondary = "Close".
    private static func makeShield(title: String, subtitle: String)
        -> ShieldConfiguration
    {
        let accent = UIColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1.0)
        let primaryText = UIColor.white
        let bodyText = UIColor(white: 1.0, alpha: 0.78)
        let background = UIColor(white: 0.05, alpha: 1.0)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: background,
            icon: UIImage(systemName: "hourglass.bottomhalf.filled"),
            title: ShieldConfiguration.Label(text: title, color: primaryText),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: bodyText
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Get 5 more minutes",
                color: primaryText
            ),
            primaryButtonBackgroundColor: accent,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: bodyText
            )
        )
    }
}
