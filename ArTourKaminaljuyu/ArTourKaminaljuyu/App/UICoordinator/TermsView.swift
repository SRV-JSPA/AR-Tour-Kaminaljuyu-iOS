//
//  Terms.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 14/05/26.
//

import SwiftUI

struct TermsView: View {
    var onBack: () -> Void = {}
    @EnvironmentObject var languageService: LanguageService

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#2A5235").ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack {
                        Color(hex: "#2A5235")
                        Image("maya")
                            .resizable()
                            .scaledToFit()
                            .frame(height: geo.size.height * 0.34)
                            .padding(.top, 16)
                    }
                    .frame(height: geo.size.height * 0.38)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(languageService.string("terms_title"))
                                    .font(.custom("PlusJakartaSans-Bold", size: 24))
                                    .foregroundColor(Color(hex: "#2D2D2D"))
                                Rectangle()
                                    .fill(Color(hex: "#E6BA62"))
                                    .frame(width: 60, height: 3)
                            }
                            .padding(.bottom, 4)

                            Text(languageService.string("terms_intro"))
                                .font(.custom("PlusJakartaSans-Medium", size: 15))
                                .foregroundColor(Color(hex: "#2D2D2D"))
                                .fixedSize(horizontal: false, vertical: true)

                            termItem(languageService.string("term_1"))
                            termItem(languageService.string("term_2"))
                            termItem(languageService.string("term_3"))
                            termItem(languageService.string("term_4"))
                            termItem(languageService.string("term_5"))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(languageService.string("terms_disclaimer_title"))
                                    .font(.custom("PlusJakartaSans-Bold", size: 15))
                                    .foregroundColor(Color(hex: "#2D2D2D"))
                                Text(languageService.string("terms_disclaimer_body"))
                                    .font(.custom("PlusJakartaSans-Medium", size: 15))
                                    .foregroundColor(Color(hex: "#2D2D2D"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 4)

                            Text(languageService.string("terms_footer"))
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

#Preview {
    TermsView()
        .environmentObject(LanguageService.shared)
}
