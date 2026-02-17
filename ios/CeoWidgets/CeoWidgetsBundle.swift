//
//  CeoWidgetsBundle.swift
//  CeoWidgets
//
//  Created by abdelhak nezzari on 16/02/2026.
//

import WidgetKit
import SwiftUI

@main
struct CeoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CeoWidgets()
        CeoWidgetsControl()
        CeoWidgetsLiveActivity()
    }
}
