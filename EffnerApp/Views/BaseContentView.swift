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
    
    var errorStatusCode: Int? {
        caches.first { $0.hasError }?.errorStatusCode
    }
    
    var isEmpty: Bool {
        !caches.isEmpty && caches.allSatisfy { $0.isEmpty }
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
    let isRefreshable: Bool
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
        isRefreshable: Bool = false,
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
        self.isRefreshable = isRefreshable
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
        let contentGroupView = Group {
            if cacheCollection.hasError {
                let effectiveErrorDescription = cacheCollection.errorStatusCode == 429
                    ? "Du hast zu viele Anfragen in kurzer Zeit gestellt. Bitte warte einen Moment und versuche es dann erneut."
                    : errorDescription
                
                ContentUnavailableView {
                    Label {
                        Text(errorTitle)
                    } icon: {
                        Image(systemName: errorSystemImage)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.yellow, .orange)
                    }
                } description: {
                    Text(effectiveErrorDescription)
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
    
        if isRefreshable {
            contentGroupView.refreshable {
                // Ein eigener Task verhindert, dass ein SwiftUI-View-Update
                // den Netzwerk-Request abbricht. Wir warten trotzdem, damit
                // der Refresh-Indikator so lange läuft, bis alles fertig ist.
                let task = Task { await cacheCollection.refreshAll() }
                await task.value
            }
        } else {
            contentGroupView
        }
    }
}
