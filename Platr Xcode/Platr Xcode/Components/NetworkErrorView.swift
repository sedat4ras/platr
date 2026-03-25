// Platr iOS — Reusable Network Error / Retry Component

import SwiftUI

struct NetworkErrorView: View {
    let message: String
    let retryAction: () async -> Void

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    isRetrying = true
                    await retryAction()
                    isRetrying = false
                }
            } label: {
                Group {
                    if isRetrying {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Try Again", systemImage: "arrow.clockwise")
                    }
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.tint)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .disabled(isRetrying)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
