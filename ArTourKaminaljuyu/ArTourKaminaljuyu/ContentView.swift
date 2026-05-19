import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewControllerWrapper()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                MapOverlayView()
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.28)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 8)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            GPSModuleInterface.shared.startTracking() // 👈 this was missing
        }
    }
}
// MARK: - MapOverlayView

struct MapOverlayView: View {

    @ObservedObject private var gps = GPSModuleInterface.shared

    var body: some View {
        VStack(spacing: 0) {

            // Status bar
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                if let dist = distanceText {
                    Text(dist)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemBackground).opacity(0.95))

            // Mapa
            MapViewRepresentable(
                userLocation: Binding(
                    get: { gps.userLocation },
                    set: { _ in }
                ),
                userHeading: Binding(
                    get: { gps.userHeading },
                    set: { _ in }
                ),
                routeCoordinates: Binding(
                    get: { gps.routeCoordinates },
                    set: { _ in }
                ),
                highlightedPOIId: Binding(
                    get: { gps.currentTargetPOI?.id },
                    set: { _ in }
                ),
                pois: gps.allPOIs
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Botones de control del tour
            HStack(spacing: 10) {
                tourControlButtons
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground).opacity(0.95))
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Tour buttons

    @ViewBuilder
    private var tourControlButtons: some View {
        let tourActive: Bool = {
            switch gps.tourState {
            case .idle, .completed: return false
            default: return true
            }
        }()

        Button(tourActive ? "⏹ Detener" : "▶ Iniciar Tour") {
            if tourActive {
                gps.stopTour()
            } else {
                gps.startTour()
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(tourActive ? .red : .green)
        .font(.caption)

        if case .atPOI(let i) = gps.tourState {
            if i < gps.allPOIs.count - 1 {
                Button("➡ Siguiente") {
                    gps.advanceToNextPOI()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            } else {
                Button("🔙 Regresar") {
                    gps.startReturnPhase()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .font(.caption)
            }
        }

        Spacer()

        if let nearest = gps.nearestPOI, nearest.level == .arrived {
            Label("¡Llegaste!", systemImage: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.green)
        }
    }

    // MARK: - Status helpers

    private var statusText: String {
        switch gps.tourState {
        case .idle:                   return "Acércate a un montículo para ver el modelo AR"
        case .navigatingToStart:      return "Camina hacia el inicio del recorrido"
        case .navigatingToPOI(let i): return "→ \(gps.allPOIs[safe: i]?.name ?? "POI \(i)")"
        case .atPOI(let i):           return "📍 \(gps.allPOIs[safe: i]?.name ?? "POI \(i)")"
        case .returning:              return "🔙 Regresando al inicio..."
        case .completed:              return "🏁 ¡Recorrido completado!"
        }
    }

    private var statusIcon: String {
        switch gps.tourState {
        case .idle:               return "figure.walk"
        case .navigatingToStart:  return "arrow.triangle.turn.up.right.circle"
        case .navigatingToPOI:    return "location.north.fill"
        case .atPOI:              return "mappin.circle.fill"
        case .returning:          return "arrow.uturn.backward.circle"
        case .completed:          return "flag.checkered.circle"
        }
    }

    private var statusColor: Color {
        switch gps.tourState {
        case .atPOI:    return .green
        case .returning: return .orange
        case .completed: return .blue
        default:         return .primary
        }
    }

    private var distanceText: String? {
        guard !gps.distanceToTarget.isNaN else { return nil }
        return "\(Int(gps.distanceToTarget))m"
    }
}

// MARK: - Safe array subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - ARViewControllerWrapper

struct ARViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController()
    }
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}


