//
//  BaseContentView.swift
//  EffnerApp
//
//  Created by Luis Bros on 17.11.25.
//

import SwiftUI
import Combine

/// Wrapper-Klasse, um mehrere Caches als ObservableObject zu kombinieren
class CacheCollection: ObservableObject {
    private let caches: [any CacheProtocol]
    private var cancellables = Set<AnyCancellable>()
    
    init(caches: [any CacheProtocol]) {
        self.caches = caches
    }
    
    var hasError: Bool {
        caches.contains { $0.hasError }
    }
    
    var isEmpty: Bool {
        caches.contains { $0.isEmpty }
    }
    
    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for cache in caches {
                group.addTask {
                    await cache.refreshCache()
                }
            }
        }
    }
    
    subscript(index: Int) -> any CacheProtocol {
        return caches[index]
    }
    
    var count: Int {
        return caches.count
    }
}

/// Generische Basis-View für Content-Views mit mehreren Caches
/// Unterstützt eine beliebige Anzahl von Caches über eine Liste
struct BaseContentView<Content: View, SkeletonView: View>: View {
    @ObservedObject var cacheCollection: CacheCollection
    
    let navigationTitle: String
    let errorTitle: String
    let errorSystemImage: String
    let errorDescription: String
    let useScrollViewReader: Bool
    let scrollToId: (CacheCollection) -> String?
    let isModal: Bool
    let content: (CacheCollection) -> Content
    let skeletonView: () -> SkeletonView
    
    init(
        caches: [any CacheProtocol],
        navigationTitle: String,
        errorTitle: String,
        errorSystemImage: String = "calendar.badge.exclamationmark",
        errorDescription: String,
        useScrollViewReader: Bool = false,
        scrollToId: @escaping (CacheCollection) -> String? = { _ in nil },
        isModal: Bool = false,
        @ViewBuilder content: @escaping (CacheCollection) -> Content,
        @ViewBuilder skeletonView: @escaping () -> SkeletonView
    ) {
        self.cacheCollection = CacheCollection(caches: caches)
        self.navigationTitle = navigationTitle
        self.errorTitle = errorTitle
        self.errorSystemImage = errorSystemImage
        self.errorDescription = errorDescription
        self.useScrollViewReader = useScrollViewReader
        self.scrollToId = scrollToId
        self.isModal = isModal
        self.content = content
        self.skeletonView = skeletonView
    }
    
    var body: some View {
        NavigationStack {
            if useScrollViewReader {
                ScrollViewReader { proxy in
                    contentView
                        .onAppear {
                            if let id = scrollToId(cacheCollection) {
                                proxy.scrollTo(id, anchor: .top)
                            }
                        }
                }
                .navigationTitle(navigationTitle)
                .presentationDragIndicator(isModal ? .visible : .hidden)
                .toolbarTitleDisplayMode(isModal ? .inline : .inlineLarge)
                .toolbar {
                    if isModal {
                        ModalToolbarComponent()
                    } else {
                        ToolbarComponent()
                    }
                }
            } else {
                contentView
                    .navigationTitle(navigationTitle)
                    .presentationDragIndicator(isModal ? .visible : .hidden)
                    .toolbarTitleDisplayMode(isModal ? .inline : .inlineLarge)
                    .toolbar {
                        if isModal {
                            ModalToolbarComponent()
                        } else {
                            ToolbarComponent()
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        Group {
            if cacheCollection.hasError {
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
                            await cacheCollection.refreshAll()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if cacheCollection.isEmpty {
                skeletonView()
            } else {
                content(cacheCollection)
            }
        }
    }
}
