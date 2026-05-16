import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    static let ceoosDailyScreenTime = Self("WakeApp Daily Screen Time")
    static let ceoosWeeklyAverageScreenTime = Self("WakeApp Weekly Average Screen Time")
}

struct DailyScreenTimeReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .ceoosDailyScreenTime
    let content: (ScreenTimeMetricConfiguration) -> ScreenTimeMetricView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> ScreenTimeMetricConfiguration {
        let totalActivityDuration = await data
            .flatMap { $0.activitySegments }
            .reduce(0.0) { $0 + $1.totalActivityDuration }

        return ScreenTimeMetricConfiguration(
            title: "TODAY",
            value: ScreenTimeMetricFormatter.string(from: totalActivityDuration),
            subtitle: "private on-device"
        )
    }
}
