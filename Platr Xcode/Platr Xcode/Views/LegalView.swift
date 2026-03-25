// Platr iOS — Legal Views (Privacy Policy, Terms of Service, Support)
// Required for App Store Guideline 5.1.1

import SwiftUI

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Last updated: 19 March 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    section("1. Information We Collect") {
                        bullet("Account data: email address, username, display name")
                        bullet("Profile data: avatar photo, bio")
                        bullet("Content you create: plate spots, comments")
                        bullet("Search history (stored locally on your device)")
                        bullet("Device token for push notifications")
                        bullet("Date of birth (for age verification only)")
                        bullet("Location data when you spot a plate (optional)")
                    }

                    section("2. How We Use Your Information") {
                        bullet("To provide and maintain the Platr service")
                        bullet("To verify your identity and manage your account")
                        bullet("To send push notifications about your plates")
                        bullet("To moderate user-generated content for community safety")
                        bullet("To improve the app experience")
                    }

                    section("3. AI-Powered Content Moderation") {
                        Text("We use Anthropic's Claude AI to review comments that have been reported by the community. This means reported comment text may be processed by a third-party AI service to determine if it violates our community guidelines. No personal identification data is sent to this service — only the comment text itself.")
                            .font(.subheadline)
                    }

                    section("4. Data Sharing") {
                        bullet("We do not sell your personal data")
                        bullet("Authentication via Google or Apple uses their respective services")
                        bullet("Reported comments may be processed by Anthropic Claude AI")
                        bullet("We do not share data with advertisers or analytics providers")
                    }

                    section("5. Data Storage & Security") {
                        bullet("Passwords are hashed using bcrypt")
                        bullet("Authentication tokens are stored in iOS Keychain")
                        bullet("Data is transmitted over HTTPS (TLS)")
                        bullet("Servers are located in Australia where possible")
                    }

                    section("6. Your Rights") {
                        bullet("Access your data via your Profile page")
                        bullet("Correct your information via Profile settings")
                        bullet("Delete your account and all associated data at any time")
                        bullet("Withdraw consent for push notifications via iOS Settings")
                    }

                    section("7. Australian Privacy Principles") {
                        Text("Platr complies with the Australian Privacy Principles (APPs) under the Privacy Act 1988 (Cth). We only collect information reasonably necessary for app functionality and take reasonable steps to protect your data from misuse.")
                            .font(.subheadline)
                    }

                    section("8. Children's Privacy") {
                        Text("Platr is not intended for users under 16 years of age. We do not knowingly collect information from children under 16, in compliance with Australian social media age requirements.")
                            .font(.subheadline)
                    }

                    section("9. Contact Us") {
                        Text("For privacy-related inquiries:")
                            .font(.subheadline)
                        Text("support@platr.app")
                            .font(.subheadline)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    @ViewBuilder
    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Terms of Service

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Last updated: 19 March 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    section("1. Acceptance of Terms") {
                        Text("By creating an account or using Platr, you agree to these Terms of Service. If you do not agree, do not use the app.")
                            .font(.subheadline)
                    }

                    section("2. Eligibility") {
                        Text("You must be at least 16 years old to use Platr. By registering, you confirm that you meet this age requirement.")
                            .font(.subheadline)
                    }

                    section("3. User Conduct") {
                        Text("You agree not to:")
                            .font(.subheadline)
                        bullet("Post content that is abusive, threatening, or discriminatory")
                        bullet("Use the app to identify, stalk, or harass vehicle owners")
                        bullet("Post personal information about others (doxxing)")
                        bullet("Share addresses, phone numbers, or names connected to plates")
                        bullet("Use the app for any illegal purpose")
                        bullet("Attempt to circumvent content moderation systems")
                        bullet("Create multiple accounts to evade bans")
                    }

                    section("4. License Plate Data") {
                        Text("Platr is a community app for car enthusiasts. License plates shared on Platr are for community interest and hobby purposes only. You must not use plate data to identify or contact vehicle owners. Violation of this rule will result in immediate account termination.")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    section("5. Content Moderation") {
                        bullet("Comments are automatically scanned for prohibited content")
                        bullet("Reported comments may be reviewed by AI moderation systems")
                        bullet("We reserve the right to remove content and suspend accounts")
                        bullet("Comments auto-hidden after 5 community reports")
                    }

                    section("6. Intellectual Property") {
                        Text("You retain ownership of content you post. By posting, you grant Platr a non-exclusive license to display your content within the app.")
                            .font(.subheadline)
                    }

                    section("7. Account Termination") {
                        Text("We may suspend or terminate accounts that violate these terms. You may delete your account at any time from your Profile settings.")
                            .font(.subheadline)
                    }

                    section("8. Disclaimer") {
                        Text("Platr is provided \"as is\" without warranties. We are not responsible for the accuracy of registration or vehicle data displayed in the app.")
                            .font(.subheadline)
                    }

                    section("9. Governing Law") {
                        Text("These terms are governed by the laws of Victoria, Australia.")
                            .font(.subheadline)
                    }

                    section("10. Contact") {
                        Text("For questions about these terms:")
                            .font(.subheadline)
                        Text("support@platr.app")
                            .font(.subheadline)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    @ViewBuilder
    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Support View

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Contact Us") {
                    Link(destination: URL(string: "mailto:support@platr.app")!) {
                        Label("Email Support", systemImage: "envelope")
                    }
                }

                Section("Resources") {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview("Privacy") { PrivacyPolicyView() }
#Preview("Terms")   { TermsOfServiceView() }
#Preview("Support") { SupportView() }
