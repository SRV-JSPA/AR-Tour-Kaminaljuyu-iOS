//
//  InstructionsView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 14/05/26.
//

import SwiftUI

struct InstructionsView: View {
    var onBack: () -> Void = {}
    @ObservedObject private var languageService = LanguageService.shared

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#4A9B8E").ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack {
                        Color(hex: "#4A9B8E")
                        Image("maya")
                            .resizable()
                            .scaledToFit()
                            .frame(height: geo.size.height * 0.34)
                            .padding(.top, 16)
                    }
                    .frame(height: geo.size.height * 0.38)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(languageService.string("instructions_title"))
                                    .font(.custom("PlusJakartaSans-Bold", size: 26))
                                    .foregroundColor(Color(hex: "#2D2D2D"))
                                Rectangle()
                                    .fill(Color(hex: "#E6BA62"))
                                    .frame(width: 60, height: 3)
                            }
                            .padding(.bottom, 4)

                            instructionItem(number: "1", text: languageService.string("instruction_1"))
                            instructionItem(number: "2", text: languageService.string("instruction_2"))
                            instructionItem(number: "3", text: languageService.string("instruction_3"))
                            instructionItem(number: "4", text: languageService.string("instruction_4"))
                            instructionItem(number: "5", text: languageService.string("instruction_5"))

                            Text(languageService.string("instructions_footer"))
                                .font(.custom("PlusJakartaSans-Bold", size: 16))
                                .foregroundColor(Color(hex: "#D15B33"))
                                .padding(.top, 4)

                            Spacer().frame(height: 40)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                    }
                    .background(Color.white)
                    .frame(height: geo.size.height * 0.62)
                }
                .ignoresSafeArea(edges: .bottom)

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

    private func instructionItem(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number + ".")
                .font(.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(Color(hex: "#2D2D2D"))
                .frame(width: 20, alignment: .leading)
            Text(text)
                .font(.custom("PlusJakartaSans-Medium", size: 16))
                .foregroundColor(Color(hex: "#2D2D2D"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview { InstructionsView() }
