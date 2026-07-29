//
//  VideoMapToggleHintView.swift
//  ArTourKaminaljuyu
//
//  Indicadores de descubrimiento para el gesto de alternar entre el video
//  del guía virtual y el mapa: un aviso animado que aparece con el primer
//  video del recorrido y un botón permanente sobre el recuadro.
//

import SwiftUI

/// Aviso temporal que se muestra sobre el recuadro del guía la primera vez
/// que arranca un video, para enseñar el gesto de toque.
struct VideoMapToggleHintView: View {
    @ObservedObject private var languageService = LanguageService.shared

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 10) {
                TapRippleIcon()

                Text(languageService.string("hint_toggle_view"))
                    .font(.custom("PlusJakartaSans-Bold", size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#D15B33"), lineWidth: 1.5)
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .center,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        // Puramente informativo: los toques pasan al gesto que ya hace el toggle.
        .allowsHitTesting(false)
    }
}

/// Mano con ondas expansivas que sugiere el toque sobre el recuadro.
private struct TapRippleIcon: View {
    @State private var animates = false

    var body: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .stroke(Color(hex: "#F5E6D3").opacity(0.8), lineWidth: 1.5)
                    .frame(width: 26, height: 26)
                    .scaleEffect(animates ? 1.7 : 0.6)
                    .opacity(animates ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 1.6)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.8),
                        value: animates
                    )
            }

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "#F5E6D3"))
                .scaleEffect(animates ? 0.88 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: animates
                )
        }
        .frame(width: 34, height: 34)
        .onAppear { animates = true }
    }
}

/// Botón permanente sobre el recuadro del guía: recuerda que el contenido se
/// puede alternar y ejecuta el mismo toggle que el toque en el recuadro.
struct VideoMapToggleButton: View {
    @ObservedObject var viewModel: VirtualGuideViewModel
    @ObservedObject private var languageService = LanguageService.shared

    var body: some View {
        Button {
            viewModel.toggleView()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.showsVideo ? "map.fill" : "play.rectangle.fill")
                    .font(.system(size: 13, weight: .semibold))

                Text(languageService.string(viewModel.showsVideo ? "toggle_to_map" : "toggle_to_video"))
                    .font(.custom("PlusJakartaSans-Bold", size: 12))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Capsule().fill(Color.black.opacity(0.6)))
            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showsVideo)
    }
}
