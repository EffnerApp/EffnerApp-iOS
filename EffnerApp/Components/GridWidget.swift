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

struct GridWidget<Content: View, Preview: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    let preview: Preview?
    let removePadding: Bool
    let contextActions: [GridWidgetAction]
    
    init(
        icon: String,
        title: String,
        iconColor: Color,
        removePadding: Bool = false,
        contextActions: [GridWidgetAction] = [],
        @ViewBuilder content: () -> Content,
        @ViewBuilder preview: () -> Preview?
    ) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.removePadding = removePadding
        self.contextActions = contextActions
        self.content = content()
        self.preview = preview()
    }
    
    var body: some View {
        PressableComponent(contextActions: contextActions) {
            widgetContent
        } preview: {
            preview
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
                
                Spacer()
                
                // Zeige > Icon wenn Context-Actions vorhanden sind
                if !contextActions.isEmpty {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
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

// Extension für GridWidget ohne Preview (nutzt Content als Preview)
extension GridWidget where Preview == Content {
    init(
        icon: String,
        title: String,
        iconColor: Color,
        removePadding: Bool = false,
        contextActions: [GridWidgetAction] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.removePadding = removePadding
        self.contextActions = contextActions
        self.content = content()
        self.preview = content()
    }
}

#Preview {
    VStack(spacing: 20) {
        // Beispiel 1: GridWidget ohne Custom-Preview (nutzt Content als Preview)
        GridWidget(
            icon: "testtube.2",
            title: "Test ohne Preview",
            iconColor: Color.blue,
            removePadding: false,
            contextActions: [
                GridWidgetAction(title: "Bearbeiten", icon: "pencil") {
                    print("Bearbeiten gedrückt")
                },
                GridWidgetAction(title: "Teilen", icon: "square.and.arrow.up") {
                    print("Teilen gedrückt")
                }
            ]
        ) {
            Text("Yeehaw!")
                .font(.largeTitle)
        }
        
        // Beispiel 2: GridWidget mit Custom-Preview
        GridWidget(
            icon: "photo.fill",
            title: "Test mit Preview",
            iconColor: Color.purple,
            removePadding: false,
            contextActions: [
                GridWidgetAction(title: "Vergrößern", icon: "arrow.up.left.and.arrow.down.right") {
                    print("Vergrößern gedrückt")
                }
            ]
        ) {
            // Normaler Content
            Text("Drücke lange!")
                .font(.title)
        } preview: {
            // Custom Preview für Long-Press
            VStack(spacing: 16) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                Text("Größere Preview!")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Dies ist eine spezielle Preview-Ansicht")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(40)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(20)
        }
        
        // Beispiel 3: GridWidget ohne Context-Actions
        GridWidget(
            icon: "star.fill",
            title: "Ohne Actions",
            iconColor: Color.yellow
        ) {
            Text("Keine Actions")
                .font(.title2)
        }
    }
    .padding()
}
