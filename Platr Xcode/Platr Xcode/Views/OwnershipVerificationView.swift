// Platr iOS — OwnershipVerificationView
// Two-day photo verification flow for plate ownership.

import SwiftUI

struct OwnershipVerificationView: View {
    let plate: Plate
    var onVerified: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var status: OwnershipStatusResponse?
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var isLoading = true

    private let api = APIService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Plate preview
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
                        .frame(width: 260)
                        Spacer()
                    }
                    .padding(.top, 8)

                    if isLoading {
                        ProgressView("Loading...")
                    } else if let status {
                        statusContent(status)
                    } else {
                        initialContent
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Claim Plate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: capturedImage) { _, newImage in
                if let img = newImage {
                    Task { await uploadPhoto(img) }
                }
            }
            .task {
                await loadStatus()
            }
        }
    }

    // MARK: - Status-based content

    @ViewBuilder
    private func statusContent(_ status: OwnershipStatusResponse) -> some View {
        switch status.status {
        case "verified":
            verifiedContent
        case "day1_complete":
            day2Content(status)
        default:
            initialContent
        }
    }

    // MARK: - Initial (no claim started)

    @ViewBuilder
    private var initialContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)

            Text("Verify Ownership")
                .font(.title3.bold())

            Text("To claim this plate, take a clear photo of it on your vehicle. You'll need to do this on two consecutive days.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Label("Day 1: Take a photo today", systemImage: "1.circle.fill")
                    .font(.subheadline)
                Label("Day 2: Take another photo tomorrow", systemImage: "2.circle.fill")
                    .font(.subheadline)
                Label("Ownership confirmed!", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            takePhotoButton
        }
    }

    // MARK: - Day 2 (day 1 complete)

    @ViewBuilder
    private func day2Content(_ status: OwnershipStatusResponse) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)

            Text("Day 1 Complete!")
                .font(.title3.bold())

            if let day1 = status.day1SubmittedAt {
                let canSubmitDay2 = day1.addingTimeInterval(20 * 3600) // 20 hours
                let deadline = day1.addingTimeInterval(48 * 3600)     // 48 hours

                if Date() < canSubmitDay2 {
                    Text("Come back after \(canSubmitDay2.formatted(date: .omitted, time: .shortened)) to take your second photo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else if Date() < deadline {
                    Text("Take your second photo now to complete verification.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    takePhotoButton
                } else {
                    Text("The 48-hour window has expired. Please start again.")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)

                    takePhotoButton
                }
            }
        }
    }

    // MARK: - Verified

    @ViewBuilder
    private var verifiedContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)

            Text("Ownership Verified!")
                .font(.title2.bold())

            Text("You are the verified owner of this plate.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                dismiss()
                onVerified?()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Take Photo Button

    @ViewBuilder
    private var takePhotoButton: some View {
        Button {
            showCamera = true
        } label: {
            HStack(spacing: 8) {
                if isUploading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "camera.fill")
                    Text("Take Photo")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isUploading ? Color(.secondarySystemBackground) : Color.accentColor)
            .foregroundStyle(isUploading ? Color.secondary : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isUploading)

        Text("Photo must be taken with camera. Gallery selection is not available.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }

    // MARK: - API

    private func loadStatus() async {
        isLoading = true
        defer { isLoading = false }
        status = try? await api.getOwnershipStatus(plateId: plate.id)
    }

    private func uploadPhoto(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process photo"
            return
        }

        isUploading = true
        errorMessage = nil
        defer { isUploading = false; capturedImage = nil }

        do {
            status = try await api.uploadOwnershipPhoto(plateId: plate.id, imageData: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
