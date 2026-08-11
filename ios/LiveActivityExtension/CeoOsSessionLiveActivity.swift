// CeoOsSessionLiveActivity.swift
//
// SwiftUI widget rendered on the Lock Screen, banner, and Dynamic Island
// for both Focus and Blackout sessions. Uses Text(timerInterval:) so the
// countdown ticks every second on-device with no push updates.

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct CeoOsSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CeoOsSessionAttributes.self) { context in
            // ── Lock screen / banner UI ──
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            // ── Dynamic Island ──
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.isBlackout ? "moon.fill" : "bolt.fill")
                            .foregroundColor(accent(for: context.state))
                        Text(context.state.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundColor(accent(for: context.state))
                        .frame(maxWidth: 90)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        timerInterval: context.state.startDate...context.state.endDate,
                        countsDown: false
                    )
                    .tint(accent(for: context.state))
                    .padding(.top, 2)
                }
            } compactLeading: {
                Image(systemName: context.state.isBlackout ? "moon.fill" : "bolt.fill")
                    .foregroundColor(accent(for: context.state))
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                    .font(.caption.monospacedDigit())
                    .frame(maxWidth: 50)
                    .foregroundColor(accent(for: context.state))
            } minimal: {
                Image(systemName: context.state.isBlackout ? "moon.fill" : "bolt.fill")
                    .foregroundColor(accent(for: context.state))
            }
            .keylineTint(accent(for: context.state))
        }
    }

    private func accent(for state: CeoOsSessionAttributes.SessionState) -> Color {
        state.isBlackout
            ? Color(red: 1.0, green: 0.62, blue: 0.04) // primary orange
            : Color(red: 0.49, green: 0.83, blue: 0.99) // focus primary
    }
}

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let state: CeoOsSessionAttributes.SessionState

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: state.isBlackout ? "moon.fill" : "bolt.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(state.isBlackout ? "Blackout" : "Focus")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundColor(Color.white.opacity(0.6))
                Text(state.title.isEmpty ? defaultTitle : state.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                ProgressView(
                    timerInterval: state.startDate...state.endDate,
                    countsDown: false,
                    label: { EmptyView() },
                    currentValueLabel: { EmptyView() }
                )
                .tint(accent)
            }

            Spacer(minLength: 0)

            Text(timerInterval: Date()...state.endDate, countsDown: true)
                .font(.title2.monospacedDigit().weight(.semibold))
                .foregroundColor(accent)
                .frame(minWidth: 78, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var accent: Color {
        state.isBlackout
            ? Color(red: 1.0, green: 0.62, blue: 0.04)
            : Color(red: 0.49, green: 0.83, blue: 0.99)
    }

    private var defaultTitle: String {
        state.isBlackout ? "Maximum focus" : "Deep work"
    }
}
