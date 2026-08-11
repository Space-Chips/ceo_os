import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct ScreenTimeReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        DailyScreenTimeReport { metric in
            ScreenTimeMetricView(metric: metric)
        }
        WeeklyAverageScreenTimeReport { metric in
            ScreenTimeMetricView(metric: metric)
        }
    }
}
