// Platr iOS — PlateView (detail screen)

import SwiftUI

struct PlateView: View {
    let plateId: UUID

    @State private var plateVM            = PlateViewModel()
    @State private var commentVM          = CommentViewModel()
    @State private var commentToReport: Comment?
    @State private var hasLoaded          = false
    @State private var showRelinqConfirm  = false
    @State private var showOwnershipSheet  = false
    @State private var isActioning        = false
    @State private var actionError: String?
    @State private var showActionError    = false

    @Environment(AuthViewModel.self) private var authVM

    private let api = APIService.shared

    // MARK: - Ownership helpers

    private var currentUserId: String? { authVM.currentUser?.id.lowercased() }

    private var isOwner: Bool {
        guard let plate = plateVM.selectedPlate,
              let uid = currentUserId,
              let oid = plate.ownerUserId else { return false }
        return oid.uuidString.lowercased() == uid
    }

    private var isClaimed: Bool { plateVM.selectedPlate?.ownerUserId != nil }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let plate = plateVM.selectedPlate {
                    plateHeader(plate)
                    metadataRow(plate)

                    // Disclaimer (Guideline 5.1.2)
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text("This app is for car enthusiasts only. Do not use plate data to identify or contact vehicle owners.")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    commentsSection(plate)
                } else if plateVM.isLoading {
                    ProgressView("Loading plate...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 80)
                } else if let error = plateVM.errorMessage {
                    NetworkErrorView(message: error) {
                        plateVM.errorMessage = nil
                        await plateVM.loadPlate(id: plateId)
                        await commentVM.loadComments(plateId: plateId)
                    }
                    .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(plateVM.selectedPlate.map { "\($0.stateCode) · \($0.plateText)" } ?? "")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if plateVM.selectedPlate != nil { plateMenu }
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await plateVM.loadPlate(id: plateId)
            await commentVM.loadComments(plateId: plateId)
        }
        .sheet(item: $commentToReport) { comment in
            ReportCommentSheet(comment: comment, commentVM: commentVM)
        }
        .sheet(isPresented: $showOwnershipSheet) {
            if let plate = plateVM.selectedPlate {
                OwnershipVerificationView(plate: plate) {
                    Task { await plateVM.loadPlate(id: plateId) }
                }
            }
        }
        .alert("Relinquish Ownership?", isPresented: $showRelinqConfirm) {
            Button("Relinquish", role: .destructive) { Task { await relinquishPlate() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will no longer be the owner of this plate.")
        }
        .alert("Error", isPresented: $showActionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "Something went wrong.")
        }
        .alert("Comment Warning", isPresented: $commentVM.showModerationWarning) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(commentVM.moderationMessage)
        }
    }

    // MARK: - ... Menu

    @ViewBuilder
    private var plateMenu: some View {
        Menu {
            if isOwner, let plate = plateVM.selectedPlate {
                Button {
                    Task { await toggleComments() }
                } label: {
                    Label(
                        plate.isCommentsOpen ? "Close Comments" : "Open Comments",
                        systemImage: plate.isCommentsOpen ? "bubble.slash" : "bubble"
                    )
                }

                Button {
                    Task { await toggleHidePlate() }
                } label: {
                    Label(
                        plate.isHidden ? "Unhide Plate" : "Hide Plate",
                        systemImage: plate.isHidden ? "eye" : "eye.slash"
                    )
                }

                Button {
                    Task { await toggleBlockReadd() }
                } label: {
                    Label(
                        plate.isBlockedReadd ? "Allow Re-add" : "Block Re-add",
                        systemImage: plate.isBlockedReadd ? "lock.open" : "lock"
                    )
                }

                Divider()
                Button(role: .destructive) { showRelinqConfirm = true } label: {
                    Label("Relinquish Ownership", systemImage: "xmark.circle")
                }
            } else if !isClaimed && currentUserId != nil {
                Button { showOwnershipSheet = true } label: {
                    Label("Claim This Plate", systemImage: "checkmark.seal")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
        }
    }

    // MARK: - Plate header

    @ViewBuilder
    private func plateHeader(_ plate: Plate) -> some View {
        HStack {
            Spacer()
            PlateTemplateRenderer(
                plateText: plate.plateText,
                style: plate.plateStyle,
                icon1: plate.icon1,
                icon2: plate.icon2,
                hasSpaceSeparator: plate.hasSpaceSeparator,
                customBgColor: plate.customBgColor.map { Color(hex: $0) }
            )
            .frame(width: 320)
            Spacer()
        }

        // Owner badge
        if isOwner {
            HStack {
                Spacer()
                Label("Your Plate", systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.green.opacity(0.1))
                    .clipShape(Capsule())
                Spacer()
            }
        }

        // Stats + Spot button
        HStack(spacing: 16) {
            statBadge(value: plate.spotCount, label: "Spots", icon: "location.fill")
            statBadge(value: plate.viewCount, label: "Views", icon: "eye.fill")

            Spacer()

            // Spot button with haptic
            Button {
                Task {
                    await plateVM.spotPlate(plate)
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            } label: {
                Label("Spot", systemImage: "binoculars.fill")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Metadata row

    @ViewBuilder
    private func metadataRow(_ plate: Plate) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Added \(plate.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let submitter = plate.submittedByUsername {
                Text("by @\(submitter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Comments

    @ViewBuilder
    private func commentsSection(_ plate: Plate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            if !plate.isCommentsOpen {
                Label("Comments are closed for this plate.", systemImage: "lock.fill")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 8)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Add a comment…", text: $commentVM.newCommentBody, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)

                    Button {
                        Task { await commentVM.postComment(plateId: plate.id) }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.tint)
                            .clipShape(Circle())
                    }
                    .disabled(commentVM.newCommentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || commentVM.isPosting)
                }

                if commentVM.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    ForEach(commentVM.comments) { comment in
                        CommentRow(comment: comment) {
                            commentToReport = comment
                        } onBlock: {
                            Task { await commentVM.blockAuthor(of: comment) }
                        }
                    }
                    if commentVM.comments.isEmpty {
                        Text("No comments yet. Be the first!")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func statBadge(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 2) {
            Label("\(value)", systemImage: icon).font(.subheadline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Ownership actions

    private func relinquishPlate() async {
        guard let plate = plateVM.selectedPlate else { return }
        isActioning = true; actionError = nil
        defer { isActioning = false }
        do {
            try await api.relinquishOwnership(plateId: plate.id)
            await plateVM.loadPlate(id: plateId)
        } catch {
            actionError = error.localizedDescription
            showActionError = true
        }
    }

    private func toggleComments() async {
        guard let plate = plateVM.selectedPlate else { return }
        isActioning = true; actionError = nil
        defer { isActioning = false }
        do {
            let updated: Plate = try await api.post(
                "/plates/\(plate.id.uuidString.lowercased())/comments/toggle",
                body: Optional<String>.none
            )
            plateVM.selectedPlate = updated
        } catch {
            actionError = error.localizedDescription
            showActionError = true
        }
    }

    private func toggleHidePlate() async {
        guard let plate = plateVM.selectedPlate else { return }
        isActioning = true; actionError = nil
        defer { isActioning = false }
        do {
            let updated = try await api.updatePlateVisibility(
                plateId: plate.id, isHidden: !plate.isHidden
            )
            plateVM.selectedPlate = updated
        } catch {
            actionError = error.localizedDescription
            showActionError = true
        }
    }

    private func toggleBlockReadd() async {
        guard let plate = plateVM.selectedPlate else { return }
        isActioning = true; actionError = nil
        defer { isActioning = false }
        do {
            let updated = try await api.updatePlateVisibility(
                plateId: plate.id, isBlockedReadd: !plate.isBlockedReadd
            )
            plateVM.selectedPlate = updated
        } catch {
            actionError = error.localizedDescription
            showActionError = true
        }
    }
}

// MARK: - CommentRow

struct CommentRow: View {
    let comment: Comment
    var onReport: () -> Void
    var onBlock:  () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(comment.body).font(.body)

            HStack(spacing: 4) {
                Text(comment.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let username = comment.authorUsername {
                    Text("by @\(username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button(role: .destructive, action: onReport) {
                        Label("Report Comment", systemImage: "flag.fill")
                    }
                    Button(role: .destructive, action: onBlock) {
                        Label("Block User", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.vertical, 8)
        Divider()
    }
}

// MARK: - Report Sheet

struct ReportCommentSheet: View {
    let comment: Comment
    var commentVM: CommentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""

    let reasons = [
        "Spam or misleading",
        "Harassment or hateful speech",
        "Violent or dangerous content",
        "Nudity or sexual content",
        "Other",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Why are you reporting this comment?") {
                    ForEach(reasons, id: \.self) { (r: String) in
                        Button {
                            reason = r
                        } label: {
                            HStack {
                                Text(r).foregroundStyle(.primary)
                                Spacer()
                                if reason == r { Image(systemName: "checkmark").foregroundStyle(.tint) }
                            }
                        }
                    }
                }
                Section {
                    Button("Submit Report") {
                        Task { await commentVM.reportComment(comment, reason: reason); dismiss() }
                    }
                    .disabled(reason.isEmpty)
                }
            }
            .navigationTitle("Report Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

#Preview { NavigationStack { PlateView(plateId: UUID()) } }
