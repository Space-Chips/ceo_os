// LiveActivityAttributes.swift
//
// Shared ActivityAttributes used by both the Focus and Blackout Live Activities.
// Keep field names in sync with the Dart payload built by
// `lib/core/services/live_activity_service.dart`.

import Foundation
import ActivityKit

@available(iOS 16.1, *)
public struct CeoOsSessionAttributes: ActivityAttributes {
    public typealias ContentState = SessionState

    public struct SessionState: Codable, Hashable {
        /// "focus" or "blackout" — drives icon + accent color in the widget.
        public var sessionType: String
        /// Short human-readable session title (e.g. "Deep Work").
        public var title: String
        /// Wall-clock millisecond timestamps so the widget can use
        /// `Text(timerInterval:)` for a live countdown without push updates.
        public var startAtMs: Int64
        public var endAtMs: Int64

        public init(
            sessionType: String,
            title: String,
            startAtMs: Int64,
            endAtMs: Int64
        ) {
            self.sessionType = sessionType
            self.title = title
            self.startAtMs = startAtMs
            self.endAtMs = endAtMs
        }

        public var startDate: Date {
            Date(timeIntervalSince1970: TimeInterval(startAtMs) / 1000.0)
        }
        public var endDate: Date {
            Date(timeIntervalSince1970: TimeInterval(endAtMs) / 1000.0)
        }
        public var isBlackout: Bool { sessionType == "blackout" }
    }

    public init() {}
}
