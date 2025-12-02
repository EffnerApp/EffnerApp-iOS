//
//  PressableComponent.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.12.25.
//
import SwiftUI

struct PressableComponent<Content: View, Preview: View>: View {
    let content: Content
    let preview: Preview?
    let contextActions: [GridWidgetAction]
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let minimumPressDuration: Double
    
    init(
        contextActions: [GridWidgetAction] = [],
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        minimumPressDuration: Double = 0.3,
        @ViewBuilder content: () -> Content,
        @ViewBuilder preview: () -> Preview
    ) {
        self.content = content()
        self.preview = preview()
        self.contextActions = contextActions
        self.hapticStyle = hapticStyle
        self.minimumPressDuration = minimumPressDuration
    }
    
    var body: some View {
        content
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: minimumPressDuration, maximumDistance: .infinity) {
                // Long press erkannt
                let impactFeedback = UIImpactFeedbackGenerator(style: hapticStyle)
                impactFeedback.impactOccurred()
            }
            .contextMenu {
                if(!contextActions.isEmpty) {
                    ForEach(contextActions.indices, id: \.self) { index in
                        Button {
                            contextActions[index].action()
                        } label: {
                            Label(contextActions[index].title, systemImage: contextActions[index].icon)
                        }
                    }
                }
            } preview: {
                preview
            }
    }
}

// Extension für PressableComponent ohne Preview
extension PressableComponent where Preview == Content {
    init(
        contextActions: [GridWidgetAction] = [],
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        minimumPressDuration: Double = 0.3,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.preview = content()
        self.contextActions = contextActions
        self.hapticStyle = hapticStyle
        self.minimumPressDuration = minimumPressDuration
    }
}
