//
//  GridWidget.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.12.25.
//

import SwiftUI

struct GridWidget<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    let removePadding: Bool
    
    init(icon: String, title: String, iconColor: Color, removePadding: Bool = false, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.removePadding = removePadding
        self.content = content()
    }
    
    var body: some View {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    GridWidget(icon: "testtube.2", title: "Test", iconColor: Color.blue, removePadding: false) {
        Text("Yeehaw!")
    }
}
