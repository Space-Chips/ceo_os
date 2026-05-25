//
//  LiveActivityExtensionBundle.swift
//  LiveActivityExtension
//
//  Created by Timo Francois on 25/05/2026.
//
//  Entry point of the Widget Extension target. Lists every widget bundled
//  by this extension. For Live Activities only the WidgetConfiguration
//  `ActivityConfiguration(for:)` is required.

import WidgetKit
import SwiftUI

@main
struct LiveActivityExtensionBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            CeoOsSessionLiveActivity()
        }
    }
}
