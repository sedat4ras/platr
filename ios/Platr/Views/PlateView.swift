// Platr iOS — PlateView (detail screen)
// [iOSSwiftAgent | iOS-002]
// Shows plate render, vehicle details (rego status), and comments section.

import SwiftUI

struct PlateView: View {
    let plateId: UUID

    @State private var plateVM  = PlateViewModel()
    @State private var commentVM = CommentViewModel()
    @State private var showReportSheet = false
    @State private var commentToReport: Comment?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Plate renderer ─────────────────────────────────────────
                if let plate = plateVM.selectedPlate {
                    plateHeader(plate)
                    vehicleDetails(plate)
                    commentsSection(plate)
                } else if plateVM.isLoading {
                    ProgressView("Loading plate...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 80)
                }
            }
            .padding()
        }
        .refreshable {
            await plateVM.loadPlate(id: plateId)
            await commentVM.loadComments(plateId: plateId)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(plateVM.selectedPlate.map { "\($0.stateCode) · \($0.plateText)" } ?? "")
        .task {
            await plateVM.loadPlate(id: plateId)
            await commentVM.loadComments(plateId: plateId)
        }
        // Report sheet
        .sheet(item: $commentToReport) { comment in
            ReportCommentSheet(comment: comment, commentVM: commentVM)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func plateHeader(_ plate: Plate) -> some View {
        HStack {
            Spacer()
            PlateTemplateRenderer(
                plateText: plate.plateText,
                style: plate.plateStyle,
                iconLeft: plate.iconLeft,
                iconRight: plate.iconRight
            )
            .frame(width: 320)
            Spacer()
        }

        // Stats row
        HStack(spacing: 24) {
            statBadge(value: plate.spotCount, label: "Spots", icon: "eye.fill")
            statBadge(value: plate.viewCount, label: "Views", icon: "binoculars.fill")
            Spacer()

            // Spot button
            Button {
                Task { await plateVM.spotPlate(plate) }
            } label: {
                Label("Spot It!", systemImage: "location.viewfinder")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func vehicleDetails(_ plate: Plate) -> some View {
        GroupBox("Vehicle Details") {
            VStack(alignment: .leading, spacing: 8) {
                regoStatusRow(plate.vehicle.regoStatus)

                if !plate.vehicle.summaryText.isEmpty {
                    LabeledContent("Vehicle", value: plate.vehicle.summaryText)
                }

                if let expiry = plate.vehicle.regoExpiryDate {
                    LabeledContent("Rego Expires", value: expiry.formatted(date: .abbreviated, time: .omitted))
                }

                if let checked = plate.vehicle.regoCheckedAt {
                    LabeledContent("Last Checked", value: checked.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Divider()

                // Recheck rego button
                Button {
                    Task { await plateVM.recheckRego() }
                } label: {
                    HStack(spacing: 6) {
                        if plateVM.isRechecking {
                            ProgressView()
                                .scaleEffect(0.75)
                                .frame(width: 14, height: 14)
                            Text("Checking rego…")
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text("Recheck Rego")
                        }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(plateVM.isRechecking ? .secondary : .accentColor)
                }
                .disabled(plateVM.isRechecking)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func regoStatusRow(_ status: RegoStatus) -> some View {
        HStack {
            Text("Rego Status")
            Spacer()
            Text(status.displayText)
                .fontWeight(.semibold)
                .foregroundStyle(statusColor(status))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor(status).opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private func statusColor(_ status: RegoStatus) -> Color {
        switch status {
        case .current:           return .green
        case .expired, .cancelled: return .red
        case .unknown, .pending:   return .gray
        }
    }

    @ViewBuilder
    private func commentsSection(_ plate: Plate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)

            if !plate.isCommentsOpen {
                Label("Comments are closed for this plate.", systemImage: "lock.fill")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 8)
            } else {
                // Comment input
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
                            .background(Color.accentColor)
                            .clipShape(Circle())
                    }
                    .disabled(commentVM.newCommentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || commentVM.isPosting)
                }

                // Comment list
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
            Label("\(value)", systemImage: icon)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - CommentRow (with UGC Report + Block)

struct CommentRow: View {
    let comment: Comment
    var onReport: () -> Void
    var onBlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(comment.body)
                .font(.body)

            HStack {
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // ── UGC: Report + Block (App Store Rule 1.2) ───────────────
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
                    ForEach(reasons, id: \.self) { r in
                        Button {
                            reason = r
                        } label: {
                            HStack {
                                Text(r)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if reason == r {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accentColor)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Submit Report") {
                        Task {
                            await commentVM.reportComment(comment, reason: reason)
                            dismiss()
                        }
                    }
                    .disabled(reason.isEmpty)
                }
            }
            .navigationTitle("Report Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

extension Comment: Identifiable {}

#Preview {
    NavigationStack {
        PlateView(plateId: UUID())
    }
}
