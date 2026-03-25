// Platr iOS — PlateMapView
// [iOSSwiftAgent | iOS-003]
//
// Victoria-centred MapKit view showing spotted plates as mini plate-style pins.
// iOS 17+ Map content builder API. Tapping a pin navigates to PlateView.

import MapKit
import SwiftUI

struct PlateMapView: View {
    @State private var plateVM = PlateViewModel()
    @State private var selectedPlateId: UUID? = nil

    private let victoriaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631),
        span: MKCoordinateSpan(latitudeDelta: 4.5, longitudeDelta: 5.0)
    )

    private var mappablePlates: [Plate] {
        plateVM.plates.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        NavigationStack {
            Map(initialPosition: .region(victoriaRegion)) {
                ForEach(mappablePlates) { plate in
                    Annotation(plate.plateText, coordinate: CLLocationCoordinate2D(
                        latitude: plate.latitude!,
                        longitude: plate.longitude!
                    )) {
                        PlateMapPin(plate: plate)
                            .onTapGesture { selectedPlateId = plate.id }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .navigationTitle("VIC Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: Binding(
                get: { selectedPlateId != nil },
                set: { if !$0 { selectedPlateId = nil } }
            )) {
                if let id = selectedPlateId {
                    PlateView(plateId: id)
                }
            }
            .overlay(alignment: .bottom) {
                if mappablePlates.isEmpty && !plateVM.isLoading {
                    Text("No spotted plates with location yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
            }
            .task {
                await plateVM.loadPlates(stateCode: "VIC")
            }
        }
    }
}

// MARK: - Map Pin

private struct PlateMapPin: View {
    let plate: Plate

    var body: some View {
        VStack(spacing: 0) {
            PlateTemplateRenderer(
                plateText: plate.plateText,
                style: plate.plateStyle,
                iconLeft: plate.iconLeft,
                iconRight: plate.iconRight
            )
            .frame(width: 90)
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

            // Pin pointer triangle
            Triangle()
                .fill(pinColor(for: plate.plateStyle))
                .frame(width: 12, height: 8)
        }
    }

    private func pinColor(for style: PlateStyle) -> Color {
        switch style {
        case .vicPrestige:                      return Color(red: 0.85, green: 0.70, blue: 0.32)
        case .vicCustomBlack, .vicSlimlineBlack,
             .vicDeluxe, .vicEuro:              return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .vicHeritage:                      return Color(red: 0.50, green: 0.30, blue: 0.10)
        case .vicEnvironment:                   return Color(red: 0.13, green: 0.55, blue: 0.13)
        default:                                return Color(red: 0.0, green: 0.18, blue: 0.56)
        }
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("VIC Map") {
    PlateMapView()
}
