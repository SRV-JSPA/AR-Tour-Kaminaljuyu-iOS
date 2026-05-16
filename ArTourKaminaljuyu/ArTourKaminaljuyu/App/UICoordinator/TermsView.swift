//
//  Terms.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 14/05/26.
//

import SwiftUI

struct TermsView: View {
    var onBack: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#2A5235").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Área superior con personaje — fija
                    ZStack {
                        Color(hex: "#2A5235")
                        Image("maya")
                            .resizable()
                            .scaledToFit()
                            .frame(height: geo.size.height * 0.34)
                            .padding(.top, 16)
                    }
                    .frame(height: geo.size.height * 0.38)

                    // Panel blanco con scroll
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Términos y Condiciones")
                                    .font(.custom("PlusJakartaSans-Bold", size: 24))
                                    .foregroundColor(Color(hex: "#2D2D2D"))
                                Rectangle()
                                    .fill(Color(hex: "#E6BA62"))
                                    .frame(width: 60, height: 3)
                            }
                            .padding(.bottom, 4)

                            Text("Bienvenido a la aplicación de recorrido virtual del Parque Arqueológico Kaminaljuyú. Al utilizar esta aplicación, usted acepta los siguientes términos:")
                                .font(.custom("PlusJakartaSans-Medium", size: 15))
                                .foregroundColor(Color(hex: "#2D2D2D"))
                                .fixedSize(horizontal: false, vertical: true)

                            termItem("Esta aplicación tiene como propósito ofrecer una experiencia educativa e interactiva basada en información histórica, arqueológica y cultural disponible hasta la fecha de su desarrollo.")
                            termItem("El contenido visual y textual ha sido elaborado a partir de investigaciones académicas, registros históricos y reconstrucciones interpretativas.")
                            termItem("Debido a limitaciones inherentes a la investigación arqueológica, algunas representaciones de estructuras, objetos y paisajes pueden no reflejar con total exactitud las condiciones originales del sitio en la antigüedad.")
                            termItem("Parte de la información presentada puede estar sujeta a cambios a medida que se desarrollen nuevas investigaciones arqueológicas o actualizaciones académicas.")
                            termItem("Esta aplicación no sustituye una visita física ni la asesoría de profesionales en arqueología o historia.")

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Descargo de responsabilidad:")
                                    .font(.custom("PlusJakartaSans-Bold", size: 15))
                                    .foregroundColor(Color(hex: "#2D2D2D"))
                                Text("Aunque se ha procurado la mayor precisión posible, la representación de ciertas estructuras, escenarios y detalles visuales puede contener elementos hipotéticos o interpretativos debido a la falta de evidencia completa o alteraciones ocurridas a lo largo del tiempo.")
                                    .font(.custom("PlusJakartaSans-Medium", size: 15))
                                    .foregroundColor(Color(hex: "#2D2D2D"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 4)

                            Text("Al utilizar esta aplicación, usted reconoce y acepta estas condiciones.")
                                .font(.custom("PlusJakartaSans-Medium", size: 15))
                                .foregroundColor(Color(hex: "#2D2D2D"))
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer().frame(height: 40)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                    }
                    .background(Color.white)
                    .frame(height: geo.size.height * 0.62)
                }
                .ignoresSafeArea(edges: .bottom)

                // Botón regresar
                VStack {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 12)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func termItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("–")
                .font(.custom("PlusJakartaSans-Bold", size: 15))
                .foregroundColor(Color(hex: "#2D2D2D"))
            Text(text)
                .font(.custom("PlusJakartaSans-Medium", size: 15))
                .foregroundColor(Color(hex: "#2D2D2D"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview { TermsView() }
