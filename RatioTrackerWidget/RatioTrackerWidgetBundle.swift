//
//  RatioTrackerWidgetBundle.swift
//  RatioTrackerWidget
//
//  Created by NJRin on 2026/7/11.
//

import WidgetKit
import SwiftUI

@main
struct RatioTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RatioTrackerWidget()
        RatioTrackerWidgetControl()
        RatioTrackerWidgetLiveActivity()
    }
}
