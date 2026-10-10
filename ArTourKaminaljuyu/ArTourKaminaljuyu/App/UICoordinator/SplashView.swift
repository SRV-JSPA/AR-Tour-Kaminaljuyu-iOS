//
//  SplashView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 16/05/26.
//

import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var offsetY: Double = 20
    
    var body: some View {
        ZStack {
            Color(hex: "#1A1A1A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("AR Tour")
                    .font(.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(Color(hex: "#ECEBC8"))

                Text("Kaminaljuyú")
                    .font(.custom("PlusJakartaSans-Bold", size: 40))
                    .foregroundColor(Color(hex: "#D15B33"))
                    .padding(.top, 4)

                Rectangle()
                    .fill(Color(hex: "#E6BA62"))
                    .frame(width: 60, height: 3)
                    .padding(.top, 8)
                    .padding(.bottom, 32)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E6BA62")))
                    .scaleEffect(1.2)
            }
            .opacity(opacity)
            .offset(y: offsetY)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 1
                    offsetY = 0
                }
            }
        }
    }
}
