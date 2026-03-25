// Platr iOS — ProfileView (Premium Redesign)

import SwiftUI
import PhotosUI

// MARK: - Profile image storage helper

private enum ProfileImageStore {
    static func save(_ data: Data, key: String) {
        let url = fileURL(key)
        try? data.write(to: url)
    }
    static func load(_ key: String) -> Data? {
        try? Data(contentsOf: fileURL(key))
    }
    static func fileURL(_ key: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(key).jpg")
    }
}

// MARK: - Profile background presets

private enum ProfileBackground: String, CaseIterable {
    case midnight    = "midnight"
    case aurora      = "aurora"
    case ember       = "ember"
    case frost       = "frost"
    case sakura      = "sakura"
    case customPhoto = "custom"

    var displayName: String {
        switch self {
        case .midnight:    "Midnight"
        case .aurora:      "Aurora"
        case .ember:       "Ember"
        case .frost:       "Frost"
        case .sakura:      "Sakura"
        case .customPhoto: "Photo"
        }
    }

    var gradient: [Color] {
        switch self {
        case .midnight:
            return [Color(red: 0.06, green: 0.06, blue: 0.18),
                    Color(red: 0.10, green: 0.08, blue: 0.28)]
        case .aurora:
            return [Color(red: 0.04, green: 0.16, blue: 0.24),
                    Color(red: 0.06, green: 0.30, blue: 0.32)]
        case .ember:
            return [Color(red: 0.20, green: 0.08, blue: 0.04),
                    Color(red: 0.42, green: 0.14, blue: 0.06)]
        case .frost:
            return [Color(red: 0.10, green: 0.14, blue: 0.22),
                    Color(red: 0.18, green: 0.24, blue: 0.36)]
        case .sakura:
            return [Color(red: 0.18, green: 0.06, blue: 0.14),
                    Color(red: 0.38, green: 0.10, blue: 0.24)]
        case .customPhoto:
            return [Color(red: 0.06, green: 0.06, blue: 0.18),
                    Color(red: 0.10, green: 0.08, blue: 0.28)]
        }
    }
}

// MARK: - ProfileView

struct ProfileView: View {
    @Bindable var authVM: AuthViewModel
    @Environment(ThemeManager.self) private var themeManager

    enum PlateTab: CaseIterable {
        case added, claimed
    }

    @State private var ownedPlates: [Plate] = []
    @State private var submittedPlates: [Plate] = []
    @State private var selectedTab: PlateTab = .added
    @State private var isLoading = false
    @State private var navigationPath = NavigationPath()
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isDeletingAccount = false
    @State private var showCustomizeSheet = false
    @State private var showSupportSheet = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false

    // Avatar
    @State private var avatarImage: UIImage?
    @State private var avatarPickerItem: PhotosPickerItem?

    // Background
    @State private var bgImage: UIImage?
    @State private var bgPickerItem: PhotosPickerItem?
    @AppStorage("profileBg") private var bgStyleRaw: String = ProfileBackground.midnight.rawValue

    private var bgStyle: ProfileBackground {
        ProfileBackground(rawValue: bgStyleRaw) ?? .midnight
    }

    private let api = APIService.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero area (full bleed)
                    heroSection

                    // Content below hero
                    VStack(spacing: 20) {
                        statsBar
                        platesSection
                        accountSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCustomizeSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .navigationDestination(for: UUID.self) { plateId in
                PlateView(plateId: plateId)
            }
            .task {
                await loadPlates()
                await authVM.fetchMe()
                loadSavedImages()
            }
            .refreshable {
                await loadPlates()
                await authVM.fetchMe()
            }
            .alert("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) { authVM.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteConfirm) {
                Button("Delete Permanently", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action is permanent and cannot be undone. All your data, plates, and comments will be removed.")
            }
            .sheet(isPresented: $showCustomizeSheet) {
                customizeSheet
            }
            .sheet(isPresented: $showSupportSheet) {
                SupportView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTerms) {
                TermsOfServiceView()
            }
        }
    }

    // MARK: - Hero Section

    @ViewBuilder
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Background
            heroBackground
                .frame(height: 280)

            // Overlay gradient for readability
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.5), location: 0.7),
                    .init(color: .black.opacity(0.7), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)

            // User info
            VStack(spacing: 14) {
                // Avatar
                avatarView
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 4)

                // Name + username
                VStack(spacing: 4) {
                    Text(authVM.currentUser?.displayName ?? authVM.currentUser?.username ?? "Platr User")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    if let user = authVM.currentUser {
                        HStack(spacing: 4) {
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                            if user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 0.30, green: 0.60, blue: 1.0))
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var heroBackground: some View {
        if bgStyle == .customPhoto, let uiImg = bgImage {
            Image(uiImage: uiImg)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 280)
                .clipped()
        } else {
            LinearGradient(
                colors: bgStyle.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            // Glow ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 90, height: 90)

            if let img = avatarImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 84, height: 84)
                    Text(initials)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var initials: String {
        let name = authVM.currentUser?.displayName ?? authVM.currentUser?.username ?? "P"
        return String(name.prefix(1)).uppercased()
    }

    // MARK: - Stats Bar

    @ViewBuilder
    private var statsBar: some View {
        HStack(spacing: 0) {
            statItem(value: submittedPlates.count, label: "Spotted", icon: "binoculars.fill")
            Divider()
                .frame(height: 32)
                .background(Color(.separator))
            statItem(value: ownedPlates.count, label: "Owned", icon: "key.fill")
            Divider()
                .frame(height: 32)
                .background(Color(.separator))
            statItem(value: ownedPlates.reduce(0) { $0 + $1.viewCount }, label: "Views", icon: "eye.fill")
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    @ViewBuilder
    private func statItem(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                Text("\(value)")
                    .font(.title3.bold().monospacedDigit())
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Plates Section

    @ViewBuilder
    private var platesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Custom tab bar
            HStack(spacing: 4) {
                tabButton(.added, count: submittedPlates.count)
                tabButton(.claimed, count: ownedPlates.count)
            }
            .padding(4)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Content
            let activePlates = selectedTab == .added ? submittedPlates : ownedPlates

            if isLoading && activePlates.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if activePlates.isEmpty {
                emptyPlatesView
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(activePlates) { plate in
                        Button { navigationPath.append(plate.id) } label: {
                            plateCard(plate)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tabButton(_ tab: PlateTab, count: Int) -> some View {
        let isActive = selectedTab == tab
        let label = tab == .added ? "Spotted" : "Claimed"

        Button {
            withAnimation(.smooth(duration: 0.2)) { selectedTab = tab }
        } label: {
            HStack(spacing: 5) {
                Text(label)
                    .font(.subheadline.bold())
                Text("\(count)")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isActive ? .white.opacity(0.2) : Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color.accentColor : Color.clear)
            .foregroundStyle(isActive ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func plateCard(_ plate: Plate) -> some View {
        HStack(spacing: 14) {
            PlateTemplateRenderer(
                plateText: plate.plateText,
                style: plate.plateStyle,
                icon1: plate.icon1,
                icon2: plate.icon2,
                hasSpaceSeparator: plate.hasSpaceSeparator,
                customBgColor: plate.customBgColor.map { Color(hex: $0) }
            )
            .frame(width: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(plate.stateCode) · \(plate.plateText)")
                    .font(.subheadline.bold())

                HStack(spacing: 12) {
                    Label("\(plate.spotCount)", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("\(plate.viewCount)", systemImage: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(plate.isCommentsOpen ? .green : .orange)
                        .frame(width: 6, height: 6)
                    Text(plate.isCommentsOpen ? "Comments open" : "Comments closed")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    @ViewBuilder
    private var emptyPlatesView: some View {
        VStack(spacing: 14) {
            Image(systemName: selectedTab == .added ? "binoculars" : "key")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text(selectedTab == .added ? "No plates spotted yet" : "No plates claimed yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(selectedTab == .added
                 ? "Use the + button in the feed to spot a plate."
                 : "Claim a plate from its detail page.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Account Section

    @ViewBuilder
    private var accountSection: some View {
        VStack(spacing: 0) {
            // App info row
            HStack {
                Label("Platr", systemImage: "car.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("v1.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)

            Divider().padding(.leading, 16)

            // Help & Support
            Button {
                showSupportSheet = true
            } label: {
                HStack {
                    Label("Help & Support", systemImage: "questionmark.circle")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 16)

            // Privacy Policy
            Button {
                showPrivacyPolicy = true
            } label: {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 16)

            // Terms of Service
            Button {
                showTerms = true
            } label: {
                HStack {
                    Label("Terms of Service", systemImage: "doc.text")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 16)

            // Sign out
            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(16)
            }

            Divider().padding(.leading, 16)

            // Delete account (Apple requirement)
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack {
                    Label("Delete Account", systemImage: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(16)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Customize Sheet

    @ViewBuilder
    private var customizeSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile Photo")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            // Preview
                            ZStack {
                                if let img = avatarImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 64, height: 64)
                                    Text(initials)
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                PhotosPicker(
                                    selection: $avatarPickerItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    Text("Choose Photo")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .onChange(of: avatarPickerItem) { _, item in
                                    Task { await loadAvatarImage(from: item) }
                                }

                                if avatarImage != nil {
                                    Button("Remove") {
                                        avatarImage = nil
                                        ProfileImageStore.save(Data(), key: "avatar")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Background picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile Background")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            ForEach(ProfileBackground.allCases, id: \.self) { bg in
                                if bg == .customPhoto {
                                    PhotosPicker(
                                        selection: $bgPickerItem,
                                        matching: .images,
                                        photoLibrary: .shared()
                                    ) {
                                        bgSwatch(bg, isSelected: bgStyleRaw == bg.rawValue)
                                    }
                                    .buttonStyle(.plain)
                                    .onChange(of: bgPickerItem) { _, item in
                                        Task { await loadBgImage(from: item) }
                                    }
                                } else {
                                    Button {
                                        withAnimation(.smooth(duration: 0.2)) {
                                            bgStyleRaw = bg.rawValue
                                            bgImage = nil
                                        }
                                    } label: {
                                        bgSwatch(bg, isSelected: bgStyleRaw == bg.rawValue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Theme picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App Theme")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            ForEach(AppTheme.allCases, id: \.self) { t in
                                Button {
                                    themeManager.theme = t
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(
                                                    LinearGradient(
                                                        colors: t.heroGradient,
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(height: 50)

                                            if themeManager.theme == t {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white)
                                                    .padding(5)
                                                    .background(.white.opacity(0.2))
                                                    .clipShape(Circle())
                                            }
                                        }

                                        Text(t.displayName)
                                            .font(.caption2.bold())
                                            .foregroundStyle(themeManager.theme == t ? .primary : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showCustomizeSheet = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func bgSwatch(_ bg: ProfileBackground, isSelected: Bool) -> some View {
        ZStack {
            if bg == .customPhoto {
                if let img = bgImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 52)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 52)
                        .overlay {
                            Image(systemName: "photo.on.rectangle")
                                .foregroundStyle(.tertiary)
                        }
                }
            } else {
                LinearGradient(colors: bg.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor, lineWidth: 2.5)
                    .frame(height: 52)
            }

            Text(bg.displayName)
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2)
                .padding(.bottom, 4)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 52)
    }

    // MARK: - Delete Account

    private func deleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        do {
            try await api.deleteAccount()
            authVM.logout()
        } catch {
            // Silently fail — user can retry
        }
    }

    // MARK: - Data Loading

    private func loadPlates() async {
        isLoading = true
        defer { isLoading = false }
        async let owned    = try? api.getOwnedPlates()
        async let submitted = try? api.getMyPlates()
        ownedPlates     = (await owned)     ?? []
        submittedPlates = (await submitted) ?? []
    }

    private func loadSavedImages() {
        if let data = ProfileImageStore.load("avatar"), !data.isEmpty {
            avatarImage = UIImage(data: data)
        }
        if let data = ProfileImageStore.load("bg"), !data.isEmpty {
            bgImage = UIImage(data: data)
        }
    }

    private func loadAvatarImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let img = UIImage(data: data) {
            avatarImage = img
            ProfileImageStore.save(data, key: "avatar")
            // Upload to backend
            if let jpegData = img.jpegData(compressionQuality: 0.8) {
                _ = try? await api.uploadAvatar(imageData: jpegData)
                await authVM.fetchMe()
            }
        }
    }

    private func loadBgImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let img = UIImage(data: data) {
            bgImage = img
            bgStyleRaw = ProfileBackground.customPhoto.rawValue
            ProfileImageStore.save(data, key: "bg")
        }
    }
}

#Preview {
    ProfileView(authVM: AuthViewModel())
        .environment(ThemeManager())
}
