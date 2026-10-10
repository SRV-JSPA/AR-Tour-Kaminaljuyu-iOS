//
//  TourConstrolsView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 24/05/26.
//

import SwiftUI
import CoreLocation

struct TourControlsView: View {
    var onBack: () -> Void = {}
    var onStartTour: () -> Void = {}
    var onFinalize: () -> Void = {}
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var gps: GPSModuleInterface

    private var distanceToStart: Double? {
        guard let userLoc = gps.userLocation else { return nil }
        let startCoord = CLLocationCoordinate2D(
            latitude: AppConfig.tourStartLatitude,
            longitude: AppConfig.tourStartLongitude
        )
        return GeoUtils.distanceInMeters(from: userLoc, to: startCoord)
    }

    private var isWithinStartRadius: Bool {
        guard let dist = distanceToStart else { return false }
        return dist <= AppConfig.tourStartRadiusMeters
    }

    private func startTourIfAllowed() {
        guard isWithinStartRadius else { return }
        onStartTour()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { startTourIfAllowed() }

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(languageService.string("tour_controls_title"))
                                    .font(.custom("PlusJakartaSans-Bold", size: 18))
                                    .foregroundColor(.white)
                                Text(languageService.string("tour_controls_subtitle"))
                                    .font(.custom("PlusJakartaSans-Regular", size: 13))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Button(action: onBack) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color(hex: "#D15B33"))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)

                        startPointBanner

                        TourControlLegendRow(icon: "arrow.uturn.backward", title: languageService.string("control_back"))
                        TourControlLegendRow(icon: "info.circle", title: languageService.string("control_info"))
                        TourControlLegendRow(icon: "play.fill", title: languageService.string("control_start"))
                        TourControlLegendRow(icon: "forward.end.fill", title: languageService.string("control_next"))
                        TourControlLegendRow(icon: "checkmark", title: languageService.string("control_finish"))
                        TourControlLegendRow(icon: "hand.tap.fill", title: languageService.string("control_toggle"))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .onTapGesture { startTourIfAllowed() }
            }
        }
    }

    @ViewBuilder
    private var startPointBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: isWithinStartRadius ? "checkmark.circle.fill" : "figure.walk")
                .foregroundColor(isWithinStartRadius ? .green : .yellow)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(isWithinStartRadius
                     ? languageService.string("ready_to_start")
                     : languageService.string("walk_to_start_point"))
                    .font(.custom("PlusJakartaSans-Bold", size: 15))
                    .foregroundColor(.white)
                Text(bannerSubtitle)
                    .font(.custom("PlusJakartaSans-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding()
        .background(
            (isWithinStartRadius ? Color.green.opacity(0.2) : Color.yellow.opacity(0.15))
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isWithinStartRadius ? Color.green : Color.yellow.opacity(0.6), lineWidth: 1)
        )
    }

    private var bannerSubtitle: String {
        if isWithinStartRadius {
            return languageService.string("tap_anywhere_to_start")
        }
        if let dist = distanceToStart {
            let template = languageService.string("distance_to_start")
            return template.replacingOccurrences(of: "%@", with: "\(Int(dist))")
        }
        return languageService.string("waiting_for_gps")
    }
}

struct TourControlLegendRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#D15B33"))
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(Color(hex: "#F5E6D3"))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#D15B33"), lineWidth: 2)
                )

            Text(title)
                .font(.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}
