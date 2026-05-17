import SwiftUI
import UIKit
import WidgetKit

private let appGroupId = "group.com.wakeapp.ceoos"

private let keyEnabledTodo = "ceo_widget_enabled_todo"
private let keyEnabledDashboard = "ceo_widget_enabled_dashboard"
private let keyEnabledHabitsToday = "ceo_widget_enabled_habits_today"
private let keyEnabledFocus = "ceo_widget_enabled_focus"
private let keyEnabledBlackout = "ceo_widget_enabled_blackout"

// Data keys (written by the app into the App Group UserDefaults).
private let keyTodoItems = "ceo_widget_data_todo_items" // [String]
private let keyTodoRemaining = "ceo_widget_data_todo_remaining" // Int
private let keyHabitsItems = "ceo_widget_data_habits_items" // [String]
private let keyHabitsCompleted = "ceo_widget_data_habits_completed" // Int
private let keyHabitsTotal = "ceo_widget_data_habits_total" // Int
private let keyDashboardTodoDone = "ceo_widget_data_dashboard_todo_done" // Int
private let keyDashboardTodoTotal = "ceo_widget_data_dashboard_todo_total" // Int
private let keyDashboardHabitsDone = "ceo_widget_data_dashboard_habits_done" // Int
private let keyDashboardHabitsTotal = "ceo_widget_data_dashboard_habits_total" // Int
private let keyDashboardEventsCount = "ceo_widget_data_dashboard_events" // Int
private let keyDashboardProgress = "ceo_widget_data_dashboard_progress" // Int 0-100
private let keyDashboardMessage = "ceo_widget_data_dashboard_message" // String
private let keyFocusDurationMinutes = "ceo_widget_focus_duration" // Int
private let keyFocusIsOn = "ceo_widget_focus_is_on" // Bool
private let keyBlackoutDurationMinutes = "ceo_widget_blackout_duration" // Int
private let keyBlackoutIsOn = "ceo_widget_blackout_is_on" // Bool
private let keyBlackoutUntil = "ceo_widget_blackout_until" // String (HH:mm) or ISO
private let keyBlackoutBlockedApps = "ceo_widget_blackout_blocked_apps" // Int
private let keyHabitsTableHabits = "ceo_widget_data_habits_table_habits" // [String]
private let keyHabitsTableDays = "ceo_widget_data_habits_table_days" // [String] 7 labels
private let keyHabitsTableStatesJson = "ceo_widget_data_habits_table_states_json" // String JSON [[Int]]
private let keyHabitsTableMore = "ceo_widget_data_habits_table_more" // Int

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
    // Medium = wide + shorter height (matches “reduce height, keep width”).
    .supportedFamilies([.systemMedium])
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

// MARK: - Native widget design system

private struct WidgetPalette {
  static let bgTop = Color(hex: 0x151515)
  static let bgBottom = Color(hex: 0x000000)
  static let textPrimary = Color(hex: 0xF5F2EA)
  static let textSecondary = Color(hex: 0xF5F2EA).opacity(0.58)
  static let textTertiary = Color(hex: 0xF5F2EA).opacity(0.35)
  static let borderSubtle = Color.white.opacity(0.16)
  static let borderSubtle2 = Color.white.opacity(0.12)
  static let cardFill = Color.white.opacity(0.055)
  static let cardFill2 = Color.white.opacity(0.045)
  static let red = Color(hex: 0xFF453A)
  static let green = Color(hex: 0x34C759)
}

private extension View {
  func widgetText(
    _ size: CGFloat,
    _ weight: Font.Weight,
    color: Color,
    minScale: CGFloat = 0.8
  ) -> some View {
    self
      .font(.system(size: size, weight: weight, design: .rounded))
      .foregroundStyle(color)
      .lineLimit(1)
      .truncationMode(.tail)
      .minimumScaleFactor(minScale)
  }
}

private extension Color {
  init(hex: UInt32) {
    let r = Double((hex >> 16) & 0xFF) / 255.0
    let g = Double((hex >> 8) & 0xFF) / 255.0
    let b = Double(hex & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }
}

private struct WidgetBackground: View {
  let padding: CGFloat
  let content: AnyView

  init(padding: CGFloat, @ViewBuilder content: () -> some View) {
    self.padding = padding
    self.content = AnyView(content())
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        LinearGradient(
          colors: [WidgetPalette.bgTop, WidgetPalette.bgBottom],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        content
          .padding(padding)
          .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
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
}

// MARK: - Compact layout tuning (priority: never cut)

private enum WidgetLayout {
  // User requirement: remove ~80% of padding vs the previous 20/22 defaults.
  // 20 -> 4  (80% removed)
  // 22 -> 6  (~73% removed, medium/large still needs a touch more for legibility)
  static let paddingSmall: CGFloat = 4
  static let paddingMediumLarge: CGFloat = 6

  // Tight vertical whitespace (keep readable, never cut).
  static let gapXS: CGFloat = 1
  static let gapS: CGFloat = 2
  static let gapM: CGFloat = 3
  static let gapL: CGFloat = 4

  static let cardPaddingS: CGFloat = 5
  static let cardPaddingM: CGFloat = 6
}

// MARK: - Widgets

private struct DashboardSmallNativeView: View {
  let todoDone: Int
  let todoTotal: Int
  let habitsDone: Int
  let habitsTotal: Int
  let events: Int
  let progress: Int
  let message: String

  var body: some View {
    WidgetBackground(padding: WidgetLayout.paddingSmall) {
      VStack(alignment: .leading, spacing: WidgetLayout.gapL) {
        Text("Dashboard")
          .widgetText(20.5, .bold, color: WidgetPalette.textPrimary, minScale: 0.82)

        VStack(alignment: .leading, spacing: WidgetLayout.gapS) {
          StatRow(label: "To‑Do", value: "\(todoDone)/\(todoTotal)")
          StatRow(label: "Habits", value: "\(habitsDone)/\(habitsTotal)")
          StatRow(label: "Events", value: "\(events)")

          ProgressBar(value: progress)

          Text(message.isEmpty ? "You're set for today" : message)
            .widgetText(13, .semibold, color: WidgetPalette.textSecondary, minScale: 0.8)
        }
        .padding(WidgetLayout.cardPaddingS)
        .background(WidgetPalette.cardFill)
        .overlay(
          RoundedRectangle(cornerRadius: 18)
            .stroke(WidgetPalette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
      }
    }
  }

  private struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
      HStack {
        Text(label)
          .widgetText(12.5, .semibold, color: WidgetPalette.textSecondary, minScale: 0.82)
        Spacer(minLength: 8)
        Text(value)
          .widgetText(14.5, .heavy, color: WidgetPalette.textPrimary, minScale: 0.78)
      }
      .frame(height: 20)
    }
  }

  private struct ProgressBar: View {
    let value: Int
    var body: some View {
      GeometryReader { geo in
        let w = geo.size.width
        let p = CGFloat(min(100, max(0, value))) / 100.0
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 999)
            .fill(Color.white.opacity(0.10))
          RoundedRectangle(cornerRadius: 999)
            .fill(WidgetPalette.textPrimary.opacity(0.35))
            .frame(width: max(8, w * p))
        }
      }
      .frame(height: 8)
    }
  }
}

private struct DashboardMediumNativeView: View {
  let todoDone: Int
  let todoTotal: Int
  let habitsDone: Int
  let habitsTotal: Int
  let events: Int
  let progress: Int
  let nextText: String

  var body: some View {
    WidgetBackground(padding: WidgetLayout.paddingMediumLarge) {
      GeometryReader { geo in
        let w = geo.size.width
        // Right side card has a max width, but never forces overflow.
        let rightW = min(170, w * 0.45)
        let leftW = max(0, w - rightW - 14)

        VStack(alignment: .leading, spacing: WidgetLayout.gapL) {
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Dashboard")
                .widgetText(24, .bold, color: WidgetPalette.textPrimary, minScale: 0.82)
              Text("Today")
                .widgetText(13, .semibold, color: WidgetPalette.textSecondary, minScale: 0.82)
            }
            Spacer(minLength: 10)
            Text("\(progress)%")
              .widgetText(24, .heavy, color: WidgetPalette.textPrimary, minScale: 0.78)
          }

          HStack(alignment: .top, spacing: WidgetLayout.gapL) {
            VStack(alignment: .leading, spacing: WidgetLayout.gapL) {
              ProgressBar(value: progress)

              HStack(spacing: WidgetLayout.gapS) {
                MetricChip(label: "To‑Do", value: "\(todoDone)/\(todoTotal)")
                MetricChip(label: "Habits", value: "\(habitsDone)/\(habitsTotal)")
                MetricChip(label: "Events", value: "\(events)")
              }
            }
            .frame(width: leftW, alignment: .leading)

            NextCard(text: nextText)
              .frame(width: rightW, alignment: .topLeading)
          }
        }
        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
      }
    }
  }

  private struct MetricChip: View {
    let label: String
    let value: String
    var body: some View {
      VStack(alignment: .leading, spacing: WidgetLayout.gapXS) {
        Text(label)
          .widgetText(12.5, .semibold, color: WidgetPalette.textSecondary, minScale: 0.82)
        Text(value)
          .widgetText(16, .heavy, color: WidgetPalette.textPrimary, minScale: 0.78)
      }
      .padding(.horizontal, 7)
      .padding(.vertical, 5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(WidgetPalette.cardFill)
      .overlay(RoundedRectangle(cornerRadius: 18).stroke(WidgetPalette.borderSubtle2, lineWidth: 1))
      .clipShape(RoundedRectangle(cornerRadius: 18))
    }
  }

  private struct NextCard: View {
    let text: String
    var body: some View {
      VStack(alignment: .leading, spacing: WidgetLayout.gapS) {
        Text("Next")
          .widgetText(12.5, .semibold, color: WidgetPalette.textSecondary, minScale: 0.82)
        Text(text.isEmpty ? "No events" : text)
          .widgetText(14, .bold, color: WidgetPalette.textPrimary, minScale: 0.8)
      }
      .padding(4)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(WidgetPalette.cardFill2)
      .overlay(RoundedRectangle(cornerRadius: 18).stroke(WidgetPalette.borderSubtle, lineWidth: 1))
      .clipShape(RoundedRectangle(cornerRadius: 18))
    }
  }

  private struct ProgressBar: View {
    let value: Int
    var body: some View {
      GeometryReader { geo in
        let w = geo.size.width
        let p = CGFloat(min(100, max(0, value))) / 100.0
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 999)
            .fill(Color.white.opacity(0.10))
          RoundedRectangle(cornerRadius: 999)
            .fill(WidgetPalette.textPrimary.opacity(0.35))
            .frame(width: max(8, w * p))
        }
      }
      .frame(height: 8)
    }
  }
}

private struct HabitsSmallNativeView: View {
  let completed: Int
  let total: Int
  let items: [String]

  var body: some View {
    WidgetBackground(padding: WidgetLayout.paddingSmall) {
      VStack(alignment: .leading, spacing: WidgetLayout.gapS) {
          HStack(alignment: .firstTextBaseline) {
            Text("Habits")
              .widgetText(23, .heavy, color: WidgetPalette.textPrimary, minScale: 0.8)
            Spacer(minLength: 8)
            Text("\(completed)/\(max(1, total))")
              .widgetText(19, .heavy, color: WidgetPalette.textPrimary, minScale: 0.78)
          }

          Text("completed")
            .widgetText(13, .semibold, color: WidgetPalette.textSecondary, minScale: 0.82)

          VStack(alignment: .leading, spacing: WidgetLayout.gapS) {
            ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { idx, name in
              HabitRow(index: idx + 1, name: name)
            }
          }
        }
    }
  }

  private struct HabitRow: View {
    let index: Int
    let name: String

    var body: some View {
      HStack(spacing: 10) {
        ZStack {
          RoundedRectangle(cornerRadius: 7)
            .fill(Color.white.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(WidgetPalette.borderSubtle2, lineWidth: 1))
          Text("\(index)")
            .widgetText(12, .bold, color: WidgetPalette.textSecondary, minScale: 0.8)
        }
        .frame(width: 22, height: 22)

        Text(name.isEmpty ? "Habit" : name)
          .widgetText(14.5, .bold, color: WidgetPalette.textPrimary, minScale: 0.8)
        Spacer(minLength: 0)
      }
      .frame(height: 26)
    }
  }
}

private struct TodoSmallNativeView: View {
  let remaining: Int
  let items: [String]

  var body: some View {
    WidgetBackground(padding: WidgetLayout.paddingSmall) {
      VStack(alignment: .leading, spacing: WidgetLayout.gapL) {
        HStack {
          Text("To‑Do")
            .widgetText(23, .heavy, color: WidgetPalette.textPrimary, minScale: 0.8)
          Spacer(minLength: 8)
          ZStack {
            Circle()
              .fill(Color.white.opacity(0.06))
              .overlay(Circle().stroke(WidgetPalette.borderSubtle, lineWidth: 1))
            Text("\(remaining)")
              .widgetText(14.5, .heavy, color: WidgetPalette.textPrimary, minScale: 0.78)
          }
          .frame(width: 32, height: 32)
        }

        VStack(alignment: .leading, spacing: WidgetLayout.gapS) {
          ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { idx, title in
            TaskRow(index: idx + 1, title: title)
          }
        }

        if items.count > 3 {
          Text("+\(items.count - 3) more")
            .widgetText(13, .semibold, color: WidgetPalette.textSecondary, minScale: 0.8)
        }
      }
    }
  }

  private struct TaskRow: View {
    let index: Int
    let title: String

    var body: some View {
      HStack(spacing: 10) {
        ZStack {
          RoundedRectangle(cornerRadius: 7)
            .fill(Color.white.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(WidgetPalette.borderSubtle2, lineWidth: 1))
          Text("\(index)")
            .widgetText(12, .bold, color: WidgetPalette.textSecondary, minScale: 0.8)
        }
        .frame(width: 22, height: 22)
        Text(title.isEmpty ? "Task" : title)
          .widgetText(14.5, .bold, color: WidgetPalette.textPrimary, minScale: 0.8)
        Spacer(minLength: 0)
      }
      .frame(height: 28)
    }
  }
}

private struct FocusSmallNativeView: View {
  let isOn: Bool

  var body: some View {
    WidgetBackground(padding: WidgetLayout.paddingSmall) {
      VStack(alignment: .leading, spacing: WidgetLayout.gapL) {
        Text("Focus")
          .widgetText(26, .heavy, color: WidgetPalette.textPrimary, minScale: 0.8)
        Text(isOn ? "ON" : "OFF")
          .widgetText(36, .black, color: isOn ? WidgetPalette.textPrimary : WidgetPalette.textSecondary, minScale: 0.75)
      }
    }
  }
}

private struct BlackoutSmallNativeView: View {
  let isOn: Bool
  let durationMinutes: Int
  let untilText: String?
  let blockedApps: Int

  var body: some View {
    WidgetBackground(padding: WidgetLayout.paddingSmall) {
      VStack(alignment: .leading, spacing: WidgetLayout.gapL) {
        Text("Blackout")
          .widgetText(26, .heavy, color: WidgetPalette.textPrimary, minScale: 0.8)

        Text(isOn ? "ON" : "OFF")
          .widgetText(36, .black, color: isOn ? WidgetPalette.red : WidgetPalette.textSecondary, minScale: 0.75)
      }
    }
  }
}


// MARK: - Fixed widgets (no "Edit Widget" required)

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
    .configurationDisplayName("WakeApp — Focus")
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
    .configurationDisplayName("WakeApp — Blackout")
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
    case .focus:
      return defaults.object(forKey: keyEnabledFocus) as? Bool ?? false
    case .blackout:
      return defaults.object(forKey: keyEnabledBlackout) as? Bool ?? false
    }
  }
}

// MARK: - View

@available(iOSApplicationExtension 16.0, *)
struct CeoFixedWidgetView: View {
  let entry: CeoFixedEntry

  var body: some View {
    let defaults = UserDefaults(suiteName: appGroupId) ?? .standard

    Group {
      if !entry.enabled {
        disabledView
      } else {
        contentView(defaults: defaults)
      }
    }
    .applyWidgetBackground()
    .ignoresSafeArea()
    .widgetURL(URL(string: routeUrlFor(entry.mode)))
    .clipped()
  }

  @ViewBuilder
  private func contentView(defaults: UserDefaults) -> some View {
    switch entry.mode {
    case .dashboard:
      let todoDone = defaults.integer(forKey: keyDashboardTodoDone)
      let todoTotal = max(0, defaults.integer(forKey: keyDashboardTodoTotal))
      let habitsDone = defaults.integer(forKey: keyDashboardHabitsDone)
      let habitsTotal = max(0, defaults.integer(forKey: keyDashboardHabitsTotal))
      let events = defaults.integer(forKey: keyDashboardEventsCount)
      let progress = min(100, max(0, defaults.integer(forKey: keyDashboardProgress)))
      let message = defaults.string(forKey: keyDashboardMessage) ?? "Keep going"
      if entry.family == .systemMedium {
        DashboardMediumNativeView(
          todoDone: todoDone,
          todoTotal: todoTotal,
          habitsDone: habitsDone,
          habitsTotal: habitsTotal,
          events: events,
          progress: progress,
          nextText: message,
        )
      } else {
        DashboardSmallNativeView(
          todoDone: todoDone,
          todoTotal: todoTotal,
          habitsDone: habitsDone,
          habitsTotal: habitsTotal,
          events: events,
          progress: progress,
          message: message,
        )
      }
    case .habits:
      HabitsSmallNativeView(
        completed: defaults.integer(forKey: keyHabitsCompleted),
        total: max(0, defaults.integer(forKey: keyHabitsTotal)),
        items: (defaults.array(forKey: keyHabitsItems) as? [String]) ?? [],
      )
    case .todo:
      TodoSmallNativeView(
        remaining: max(0, defaults.integer(forKey: keyTodoRemaining)),
        items: (defaults.array(forKey: keyTodoItems) as? [String]) ?? [],
      )
    case .focus:
      FocusSmallNativeView(
        isOn: defaults.object(forKey: keyFocusIsOn) as? Bool ?? false,
      )
    case .blackout:
      BlackoutSmallNativeView(
        isOn: defaults.object(forKey: keyBlackoutIsOn) as? Bool ?? false,
        durationMinutes: max(15, (defaults.object(forKey: keyBlackoutDurationMinutes) as? Int) ?? 120),
        untilText: defaults.string(forKey: keyBlackoutUntil),
        blockedApps: max(0, defaults.integer(forKey: keyBlackoutBlockedApps)),
      )
    }
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

  private func routeUrlFor(_ mode: CeoWidgetResolvedMode) -> String {
    switch mode {
    case .todo: return "ceoos:///tasks"
    case .habits: return "ceoos:///habits"
    case .dashboard: return "ceoos:///home"
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
