//
//  MenuSquareCardView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 14/05/26.
//

import SwiftUI

struct MenuSquareCardView: View {
    let icon: AnyView
    let title: String
    let gradientStart: Color
    let gradientEnd: Color
    let strokeColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                icon
                    .frame(width: 36, height: 36)

                Text(title)
                    .font(.custom("PlusJakartaSans-Bold", size: 14))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: isPressed
                                ? [Color(hex: "#E5E5C8"), Color(hex: "#E2BFA1")]
                                : [gradientStart, gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(strokeColor, lineWidth: isPressed ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
