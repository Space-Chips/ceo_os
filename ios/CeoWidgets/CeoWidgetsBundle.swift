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
        if #available(iOSApplicationExtension 18.0, *) {
            CeoWidgetsControl()
            CeoWidgetsLiveActivity()
        }
    }
}

