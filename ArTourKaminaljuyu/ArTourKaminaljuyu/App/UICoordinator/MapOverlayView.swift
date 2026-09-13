//
//  MapOverlayView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 16/05/26.
//

import SwiftUI
import Combine
import CoreLocation

struct MapOverlayView: View {

    @EnvironmentObject var gps: GPSModuleInterface
    @EnvironmentObject var languageService: LanguageService

    // MARK: - Aviso temporal de distancia
    // Cada `noticePeriodSeconds` el mensaje de estado se sustituye por el aviso
    // de distancia durante `noticeDurationSeconds` y luego vuelve al predeterminado.
    @State private var showsDistanceNotice = false
    private let noticePeriodSeconds: Double = 10
    private let noticeDurationSeconds: Double = 4

    var body: some View {
        VStack(spacing: 0) {

            // Status bar
            HStack {
                Image(systemName: displayedStatus.icon)
                    .foregroundColor(displayedStatus.color)
                Text(displayedStatus.text)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .id(showsDistanceNotice)
                    .transition(.opacity)
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
            .task { await runDistanceNoticeLoop() }

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
                pois: gps.allPOIs,
                tourStartCoordinate: CLLocationCoordinate2D(
                    latitude: AppConfig.tourStartLatitude,
                    longitude: AppConfig.tourStartLongitude
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Aviso temporal de distancia

    private func runDistanceNoticeLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(noticePeriodSeconds))
            guard !Task.isCancelled else { return }
            guard distanceNoticeText != nil else { continue }

            withAnimation(.easeInOut(duration: 0.25)) { showsDistanceNotice = true }
            try? await Task.sleep(for: .seconds(noticeDurationSeconds))
            withAnimation(.easeInOut(duration: 0.25)) { showsDistanceNotice = false }
        }
    }

    // Distancia al montículo relevante: el POI objetivo durante el tour,
    // o el más cercano detectado en exploración libre.
    private var distanceNoticeText: String? {
        let poi: POILocation
        let distance: Double

        switch gps.tourState {
        case .navigatingToPOI, .atPOI:
            guard let target = gps.currentTargetPOI,
                  let userLoc = gps.userLocation else { return nil }
            poi = target
            distance = GeoUtils.distanceInMeters(from: userLoc, to: target.coordinate)

        case .idle:
            guard let nearest = gps.nearestPOI else { return nil }
            poi = nearest.poi
            distance = nearest.distanceMeters

        default:
            return nil
        }

        guard distance.isFinite else { return nil }
        let template = languageService.string("distance_to_poi")
        let distanceStr = "\(Int(distance.rounded()))"
        return template.replacingOccurrences(of: "%@", with: distanceStr, options: [], range: template.range(of: "%@"))
            .replacingOccurrences(of: "%@", with: poi.localizedName)
    }

    private var displayedStatus: (icon: String, text: String, color: Color) {
        if showsDistanceNotice, let notice = distanceNoticeText {
            return ("location.circle.fill", notice, .orange)
        }
        return (statusIcon, statusText, statusColor)
    }

    // MARK: - Status helpers

    private var statusText: String {
        switch gps.tourState {
        case .idle:
            return languageService.string("status_idle")
        case .navigatingToStart:
            return languageService.string("status_navigating_to_start")
        case .navigatingToPOI(let i):
            let poiName = gps.allPOIs[safe: i]?.localizedName ?? "POI \(i)"
            return "→ \(poiName)"
        case .atPOI(let i):
            let poiName = gps.allPOIs[safe: i]?.localizedName ?? "POI \(i)"
            return "📍 \(poiName)"
        case .returning:
            return languageService.string("status_returning")
        case .completed:
            return languageService.string("status_completed")
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
