import DeviceActivity
import ExtensionKit
import SwiftUI

struct WeeklyAverageScreenTimeReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .ceoosWeeklyAverageScreenTime
    let content: (ScreenTimeMetricConfiguration) -> ScreenTimeMetricView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> ScreenTimeMetricConfiguration {
        let totalActivityDuration = await data
            .flatMap { $0.activitySegments }
            .reduce(0.0) { $0 + $1.totalActivityDuration }

        return ScreenTimeMetricConfiguration(
            title: "7D AVG",
            value: ScreenTimeMetricFormatter.string(from: totalActivityDuration / 7.0),
            subtitle: "last 7 days"
        )
    }
}
