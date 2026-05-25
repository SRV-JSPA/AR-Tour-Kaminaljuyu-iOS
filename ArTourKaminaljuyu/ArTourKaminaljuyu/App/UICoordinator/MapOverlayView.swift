//
//  MapOverlayView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 16/05/26.
//

import SwiftUI
import Combine

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
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
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
