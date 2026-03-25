// Platr iOS — Onboarding Walkthrough (first launch only)

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompleted = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "binoculars.fill",
            title: "Spot Plates",
            description: "Discover and log number plates you see around Victoria. Build your collection of unique finds.",
            color: .blue
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: "Join the Community",
            description: "Comment, share spots, and connect with other car enthusiasts across the state.",
            color: .purple
        ),
        OnboardingPage(
            icon: "checkmark.seal.fill",
            title: "Claim Your Plate",
            description: "Own a custom plate? Verify ownership and manage comments from your profile.",
            color: .green
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: currentPage)

            // Bottom section
            VStack(spacing: 20) {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color(.tertiaryLabel))
                            .frame(width: index == currentPage ? 10 : 7,
                                   height: index == currentPage ? 10 : 7)
                            .animation(.smooth(duration: 0.2), value: currentPage)
                    }
                }

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasCompleted = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Skip button (not on last page)
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        hasCompleted = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon circle
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(page.color)
            }

            Text(page.title)
                .font(.title.bold())

            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
