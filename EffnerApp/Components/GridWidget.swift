//
//  GridWidget.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.12.25.
//

import SwiftUI

struct GridWidgetAction {
    let title: String
    let icon: String
    let action: () -> Void
}

struct GridWidget<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    let removePadding: Bool
    let contextActions: [GridWidgetAction]
    
    init(icon: String, title: String, iconColor: Color, removePadding: Bool = false, contextActions: [GridWidgetAction] = [], @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.removePadding = removePadding
        self.contextActions = contextActions
        self.content = content()
    }
    
    var body: some View {
        PressableComponent(contextActions: contextActions) {
            widgetContent
        } 
    }
    
    @ViewBuilder
    private var widgetContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header mit Icon und Titel
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            
            // Custom Content
            content
                .padding(.horizontal, removePadding ? 0 : nil)
                .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    VStack {
        GridWidget(
            icon: "testtube.2",
            title: "Test",
            iconColor: Color.blue,
            removePadding: false,
            contextActions: [
                GridWidgetAction(title: "Bearbeiten", icon: "pencil") {
                    print("Bearbeiten gedrückt")
                },
                GridWidgetAction(title: "Teilen", icon: "square.and.arrow.up") {
                    print("Teilen gedrückt")
                },
                GridWidgetAction(title: "Löschen", icon: "trash") {
                    print("Löschen gedrückt")
                }
            ]
        ) {
            Text("Yeehaw!")
        }
        
        GridWidget(
            icon: "testtube.2",
            title: "Test2",
            iconColor: Color.blue,
            removePadding: false,
            contextActions: [
            ]
        ) {
            Text("Yeehaw!")
        }
    }

}
