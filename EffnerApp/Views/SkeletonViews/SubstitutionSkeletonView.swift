//
//  SubstitutionSkeletonView.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//
import SwiftUI

struct SubstitutionSkeletonView: View {
    var body: some View {
        List {
            // Simulate 3 days with substitution plans
            ForEach(0..<2, id: \.self) { dayIndex in
                Section(header: SubstitutionSkeletonHeaderView()) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Simulate Information section
                        if dayIndex == 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Informationen")
                                    .font(.headline)
                                
                                HStack(alignment: .top) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14))
                                    Text("Placeholder information text here")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        }
                        
                        // Simulate substitutions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vertretungen")
                                .font(.headline)
                            
                            ForEach(0..<4, id: \.self) { index in
                                SubstitutionSkeletonRow(isLast: index == 3)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.systemBackground))
        .redacted(reason: .placeholder)
    }
}

struct SubstitutionSkeletonHeaderView: View {
    var body: some View {
        HStack {
            Text("Zukünftige Tage")
                .font(.headline)
            
            Spacer()
            
            Text("01.01.2024")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SubstitutionSkeletonRow: View {
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                // Period number
                Text("1.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(width: 40, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Teacher and substitute
                    HStack(spacing: 4) {
                        Text("Teacher")
                            .font(.body)
                            .strikethrough()
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Substitute")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    // Room and info
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "door.left.hand.open")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            Text("Room")
                                .font(.subheadline)
                        }
                        
                        Text("Additional info")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 4)
            
            if !isLast {
                Divider()
            }
        }
    }
}

#Preview {
    SubstitutionSkeletonView()
}
