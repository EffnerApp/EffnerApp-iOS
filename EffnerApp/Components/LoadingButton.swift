//
//  LoadingButton.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import SwiftUI

struct LoadingButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private var isLoading: Bool

    init(isLoading: Bool) {
        self.isLoading = isLoading
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
            }

            configuration.label
        }
        .opacity(configuration.isPressed ? 0.2 : 1)
        .animation(.default, value: isEnabled)
        .animation(.default, value: isLoading)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}


struct LoadingButton<ResultType, Label: View>: View {
    @State private var loadingTask: Task<Void, Never>?
    private var isLoading: Bool { loadingTask != nil }

    let action: () async -> ResultType
    let onResult: (ResultType) -> Void
    let label: () -> Label

    var body: some View {
        Button(action: {
            guard loadingTask == nil else { return }
            loadingTask = Task {
                let result = await action()
                await MainActor.run {
                    onResult(result)
                    loadingTask = nil
                }
            }
        }) {
            label()
        }
        .buttonStyle(LoadingButtonStyle(isLoading: isLoading))
        .disabled(isLoading)
        .onDisappear {
            loadingTask?.cancel()
            loadingTask = nil
        }
    }
}

#Preview {
    LoadingButton(action: {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return "Done!"
    }, onResult: { result in
        print(result)
    }, label: {
        Text("Click me")
    })
}
