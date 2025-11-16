//
//  SubstitutionSkeletonView.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//
import SwiftUI

struct SubstitutionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("1.")
                    .font(.title2)
                    .frame(width: 40, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Placeholder Teacher")
                        .font(.body)
                    Text("Placeholder Info")
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SubstitutionSkeletonView()
}
