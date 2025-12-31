//
//  FocusFlowWidgetBundle.swift
//  FocusFlowWidget
//
//  Created by Yasmin Farisah Salma on 01/01/26.
//

import WidgetKit
import SwiftUI

@main
struct FocusFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowWidget()
        FocusFlowWidgetControl()
        FocusFlowWidgetLiveActivity()
    }
}
