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
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Controles del Tour AR")
                            .font(.custom("PlusJakartaSans-Bold", size: 18))
                            .foregroundColor(.white)
                        Text("Toca cualquier lugar para continuar")
                            .font(.custom("PlusJakartaSans-Regular", size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Button(action: onStartTour) {
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
                
                // Botones
                TourControlButton(icon: "arrow.uturn.backward", title: "Regresar al menú principal", action: onBack)
                TourControlButton(icon: "info.circle", title: "Ver información del POI cercano", action: {})
                TourControlButton(icon: "play.fill", title: "Iniciar recorrido guiado automático", action: onStartTour)
                TourControlButton(icon: "forward.end.fill", title: "Avanzar al siguiente punto de interés", action: {})
                TourControlButton(icon: "checkmark", title: "Finalizar el recorrido guiado", action: onFinalize)
            }
            .padding()
        }
    }
}

struct TourControlButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
}
