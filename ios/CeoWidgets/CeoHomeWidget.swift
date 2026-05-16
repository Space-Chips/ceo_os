import SwiftUI
import UIKit
import WidgetKit

private let appGroupId = "group.com.wakeapp.ceoos"

private let keyTodoSmall = "ceo_widget_todo_small"
private let keyTodoLarge = "ceo_widget_todo_large"
private let keyDashboardSmall = "ceo_widget_dashboard_small"
private let keyDashboardLarge = "ceo_widget_dashboard_large"
private let keyHabitsSmall = "ceo_widget_habits_small"
private let keyHabitsLarge = "ceo_widget_habits_large"
private let keyHabitsTableSmall = "ceo_widget_habits_table_small"
private let keyHabitsTableLarge = "ceo_widget_habits_table_large"
private let keyFocusSmall = "ceo_widget_focus_small"
private let keyFocusLarge = "ceo_widget_focus_large"
private let keyBlackoutSmall = "ceo_widget_blackout_small"
private let keyBlackoutLarge = "ceo_widget_blackout_large"

private let keyEnabledTodo = "ceo_widget_enabled_todo"
private let keyEnabledDashboard = "ceo_widget_enabled_dashboard"
private let keyEnabledHabitsToday = "ceo_widget_enabled_habits_today"
private let keyEnabledHabitsTable = "ceo_widget_enabled_habits_table"
private let keyEnabledFocus = "ceo_widget_enabled_focus"
private let keyEnabledBlackout = "ceo_widget_enabled_blackout"

enum CeoWidgetResolvedMode {
  case todo
  case dashboard
  case habits
  case habitsTable
  case focus
  case blackout
}

@available(iOSApplicationExtension 16.0, *)
struct CeoHabitsTableWidget: Widget {
  let kind: String = "com.wakeapp.ceoos.widget.habits.table"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CeoFixedProvider(mode: .habitsTable)) { entry in
      CeoFixedWidgetView(entry: entry)
    }
    .configurationDisplayName("WakeApp — Habits Table")
    .description("A compact habits table.")
    .supportedFamilies([.systemMedium])
  }
}

// MARK: - Fixed widgets (no “Edit Widget” required)

@available(iOSApplicationExtension 16.0, *)
struct CeoTodoWidget: Widget {
  let kind: String = "com.wakeapp.ceoos.widget.todo"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CeoFixedProvider(mode: .todo)) { entry in
      CeoFixedWidgetView(entry: entry)
    }
    .configurationDisplayName("WakeApp — To‑Do")
    .description("Your top tasks on the Home Screen.")
    .supportedFamilies([.systemSmall])
  }
}

@available(iOSApplicationExtension 16.0, *)
struct CeoDashboardWidget: Widget {
  let kind: String = "com.wakeapp.ceoos.widget.dashboard"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CeoFixedProvider(mode: .dashboard)) { entry in
      CeoFixedWidgetView(entry: entry)
    }
    .configurationDisplayName("WakeApp — Dashboard")
    .description("A compact dashboard for tasks and habits.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@available(iOSApplicationExtension 16.0, *)
struct CeoHabitsWidget: Widget {
  let kind: String = "com.wakeapp.ceoos.widget.habits"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CeoFixedProvider(mode: .habits)) { entry in
      CeoFixedWidgetView(entry: entry)
    }
    .configurationDisplayName("WakeApp — Habits Today")
    .description("Your habits for today.")
    .supportedFamilies([.systemSmall])
  }
}

@available(iOSApplicationExtension 16.0, *)
struct CeoFocusWidget: Widget {
  let kind: String = "com.wakeapp.ceoos.widget.focus"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CeoFixedProvider(mode: .focus)) { entry in
      CeoFixedWidgetView(entry: entry)
    }
    .configurationDisplayName("WakeApp - Focus")
    .description("Start a Focus session quickly.")
    .supportedFamilies([.systemSmall])
  }
}

@available(iOSApplicationExtension 16.0, *)
struct CeoBlackoutWidget: Widget {
  let kind: String = "com.wakeapp.ceoos.widget.blackout"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CeoFixedProvider(mode: .blackout)) { entry in
      CeoFixedWidgetView(entry: entry)
    }
    .configurationDisplayName("WakeApp - Blackout")
    .description("Start a Blackout session quickly.")
    .supportedFamilies([.systemSmall])
  }
}

// MARK: - Timeline

@available(iOSApplicationExtension 16.0, *)
struct CeoFixedEntry: TimelineEntry {
  let date: Date
  let mode: CeoWidgetResolvedMode
  let family: WidgetFamily
  let enabled: Bool
}

@available(iOSApplicationExtension 16.0, *)
struct CeoFixedProvider: TimelineProvider {
  let mode: CeoWidgetResolvedMode

  func placeholder(in context: Context) -> CeoFixedEntry {
    CeoFixedEntry(
      date: Date(),
      mode: mode,
      family: context.family,
      enabled: true,
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (CeoFixedEntry) -> Void) {
    completion(
      CeoFixedEntry(
        date: Date(),
        mode: mode,
        family: context.family,
        enabled: isEnabled(mode),
      ),
    )
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CeoFixedEntry>) -> Void) {
    let entry = CeoFixedEntry(
      date: Date(),
      mode: mode,
      family: context.family,
      enabled: isEnabled(mode),
    )
    completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60))))
  }

  private func isEnabled(_ mode: CeoWidgetResolvedMode) -> Bool {
    let defaults = UserDefaults(suiteName: appGroupId) ?? .standard
    switch mode {
    case .todo:
      return defaults.object(forKey: keyEnabledTodo) as? Bool ?? false
    case .dashboard:
      return defaults.object(forKey: keyEnabledDashboard) as? Bool ?? false
    case .habits:
      return defaults.object(forKey: keyEnabledHabitsToday) as? Bool ?? false
    case .habitsTable:
      return defaults.object(forKey: keyEnabledHabitsTable) as? Bool ?? false
    case .focus:
      return defaults.object(forKey: keyEnabledFocus) as? Bool ?? true
    case .blackout:
      return defaults.object(forKey: keyEnabledBlackout) as? Bool ?? true
    }
  }
}

// MARK: - View

@available(iOSApplicationExtension 16.0, *)
struct CeoFixedWidgetView: View {
  let entry: CeoFixedEntry

  var body: some View {
    let large = entry.family != .systemSmall
    let imageKey = imageKeyFor(entry.mode, large: large)
    let defaults = UserDefaults(suiteName: appGroupId) ?? .standard
    let path = defaults.string(forKey: imageKey)

    Group {
      if !entry.enabled {
        disabledView
      } else if let path, let image = UIImage(contentsOfFile: path) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        emptyView
      }
    }
    .applyWidgetBackground()
    .ignoresSafeArea()
    .widgetURL(URL(string: routeUrlFor(entry.mode)))
    .clipped()
  }

  private var disabledView: some View {
    ZStack {
      Color.black.opacity(0.65)
      VStack(spacing: 10) {
        Text("Disabled")
          .font(.headline)
          .foregroundStyle(.white)
        Text("Enable this widget in Widget Configuration.")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 10)
      }
    }
  }

  private var emptyView: some View {
    ZStack {
      Color.black.opacity(0.78)
      VStack(spacing: 8) {
        Text(displayNameFor(entry.mode))
          .font(.headline)
          .foregroundStyle(.white)
          .multilineTextAlignment(.center)
        Text("Open WakeApp to refresh.")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 10)
      }
    }
  }

  private func imageKeyFor(_ mode: CeoWidgetResolvedMode, large: Bool) -> String {
    switch mode {
    case .todo: return large ? keyTodoLarge : keyTodoSmall
    case .habits: return large ? keyHabitsLarge : keyHabitsSmall
    case .dashboard: return large ? keyDashboardLarge : keyDashboardSmall
    case .habitsTable: return large ? keyHabitsTableLarge : keyHabitsTableSmall
    case .focus: return large ? keyFocusLarge : keyFocusSmall
    case .blackout: return large ? keyBlackoutLarge : keyBlackoutSmall
    }
  }

  private func routeUrlFor(_ mode: CeoWidgetResolvedMode) -> String {
    switch mode {
    case .todo: return "ceoos:///tasks"
    case .habits: return "ceoos:///habits"
    case .dashboard: return "ceoos:///home"
    case .habitsTable: return "ceoos:///habits"
    case .focus: return "ceoos:///focus?start=1&duration=25"
    case .blackout: return "ceoos:///ceo-mode?start=1&duration=120"
    }
  }

  private func displayNameFor(_ mode: CeoWidgetResolvedMode) -> String {
    switch mode {
    case .todo: return "To-Do"
    case .habits: return "Habits"
    case .dashboard: return "Dashboard"
    case .habitsTable: return "Habits Table"
    case .focus: return "Focus"
    case .blackout: return "Blackout"
    }
  }
}

@available(iOSApplicationExtension 16.0, *)
private extension View {
  @ViewBuilder
  func applyWidgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(Color.black, for: .widget)
    } else {
      self.background(Color.black)
    }
  }
}
