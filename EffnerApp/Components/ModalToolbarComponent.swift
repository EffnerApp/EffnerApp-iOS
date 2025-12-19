//
//  ModalToolbarComponent.swift
//  EffnerApp
//
//  Created by Luis Bros on 19.12.25.
//

//
//  Toolbar.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//
import SwiftUI

struct ModalToolbarComponent: ToolbarContent {
    @Environment(\.dismiss) var dismiss

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .fontWeight(.semibold)
            }
    
        }
    }
}


#Preview {
    NavigationStack {
        Text("Modal Toolbar Preview")
            .toolbar {
                ModalToolbarComponent()
            }
    }
}
