//
//  BaseContentView.swift
//  EffnerApp
//
//  Created by Luis Bros on 17.11.25.
//

import SwiftUI

/// Generische Basis-View für alle Content-Views (Exams, Substitutions, Timetable)
struct BaseContentView<Cache: CacheProtocol, Content: View, SkeletonView: View>: View {
    @ObservedObject var cache: Cache
    
    let navigationTitle: String
    let errorTitle: String
    let errorSystemImage: String
    let errorDescription: String
    let useScrollViewReader: Bool
    let scrollToId: (Cache) -> String?
    let content: (Cache) -> Content
    let skeletonView: () -> SkeletonView
    
    init(
        cache: Cache,
        navigationTitle: String,
        errorTitle: String,
        errorSystemImage: String = "calendar.badge.exclamationmark",
        errorDescription: String,
        useScrollViewReader: Bool = false,
        scrollToId: @escaping (Cache) -> String? = { _ in nil },
        @ViewBuilder content: @escaping (Cache) -> Content,
        @ViewBuilder skeletonView: @escaping () -> SkeletonView
    ) {
        self.cache = cache
        self.navigationTitle = navigationTitle
        self.errorTitle = errorTitle
        self.errorSystemImage = errorSystemImage
        self.errorDescription = errorDescription
        self.useScrollViewReader = useScrollViewReader
        self.scrollToId = scrollToId
        self.content = content
        self.skeletonView = skeletonView
    }
    
    var body: some View {
        NavigationStack {
            if useScrollViewReader {
                ScrollViewReader { proxy in
                    contentView
                        .onAppear {
                            if let id = scrollToId(cache) {
                                proxy.scrollTo(id, anchor: .top)
                            }
                        }
                }
                .navigationTitle(navigationTitle)
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarComponent()
                }
            } else {
                contentView
                    .navigationTitle(navigationTitle)
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarComponent()
                    }
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        Group {
            if cache.hasError {
                ContentUnavailableView {
                    Label {
                        Text(errorTitle)
                    } icon: {
                        Image(systemName: errorSystemImage)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.yellow, .orange)
                    }
                } description: {
                    Text(errorDescription)
                } actions: {
                    Button("Erneut versuchen") {
                        Task {
                            await cache.refreshCache()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if cache.isEmpty {
                skeletonView()
            } else {
                content(cache)
            }
        }
    }
}
