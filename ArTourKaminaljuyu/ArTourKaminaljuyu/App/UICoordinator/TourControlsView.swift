//
//  TourConstrolsView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 24/05/26.
//

import SwiftUI

struct TourControlsView: View {
    var onBack: () -> Void = {}
    var onStartTour: () -> Void = {}
    var onFinalize: () -> Void = {}
    @ObservedObject private var languageService = LanguageService.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onStartTour() }

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

                        TourControlLegendRow(icon: "arrow.uturn.backward", title: languageService.string("control_back"))
                        TourControlLegendRow(icon: "info.circle", title: languageService.string("control_info"))
                        TourControlLegendRow(icon: "play.fill", title: languageService.string("control_start"))
                        TourControlLegendRow(icon: "forward.end.fill", title: languageService.string("control_next"))
                        TourControlLegendRow(icon: "checkmark", title: languageService.string("control_finish"))
                        TourControlLegendRow(icon: "hand.tap.fill", title: languageService.string("control_toggle"))
                    }
                    .padding()
                    // Centra la lista como antes; el scroll solo entra en juego
                    // cuando el contenido no cabe (pantallas pequeñas).
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                // El scroll cubre el fondo: mantiene el "toca cualquier lugar para continuar".
                .onTapGesture { onStartTour() }
            }
        }
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
