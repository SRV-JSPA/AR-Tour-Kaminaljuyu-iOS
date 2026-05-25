//
//  MainMenuView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 14/05/26.
//

import SwiftUI
import AVKit

struct ArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width * 0.52
        let centerY = radius * 0.85
        path.move(to: CGPoint(x: 0, y: centerY))
        path.addArc(
            center: CGPoint(x: rect.width / 2, y: centerY),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct MainMenuView: View {
    var onGuidedTour: () -> Void = {}
    var onFreeTour: () -> Void = {}
    var onInstructions: () -> Void = {}
    var onTerms: () -> Void = {}

    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fondo oscuro
                LinearGradient(
                    colors: [Color(hex: "#1a1a1a"), Color(hex: "#2d2d2d"), Color(hex: "#0f0f0f")],
                    startPoint: .topTrailing, endPoint: .bottomLeading
                )
                .ignoresSafeArea()

                // Video de fondo
                if let player = player {
                    VideoPlayerView(player: player)
                        .ignoresSafeArea()
                        .opacity(0.4)
                        .allowsHitTesting(false)
                }

                // Panel blanco
                VStack(spacing: 0) {
                    Spacer().frame(height: geo.size.height * 0.20)

                    VStack(alignment: .leading, spacing: 0) {
                        // Espacio para el personaje
                        Spacer().frame(height: geo.size.height * 0.13)

                        // Textos
                        Text("Bienvenidos al\nParque Arqueológico")
                            .font(.custom("PlusJakartaSans-Bold", size: 22))
                            .foregroundColor(Color(hex: "#2D2D2D"))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 2)

                        Text("Kaminaljuyú")
                            .font(.custom("PlusJakartaSans-Bold", size: 32))
                            .foregroundColor(Color(hex: "#D15B33"))

                        Rectangle()
                            .fill(Color(hex: "#E6BA62"))
                            .frame(width: 60, height: 3)
                            .padding(.top, 4)
                            .padding(.bottom, 24)

                        // Tour Guiado
                        MenuCardView(
                            icon: AnyView(GuidedTourIcon(size: 28)),
                            title: "Tour Guiado",
                            gradientStart: Color(hex: "#E8C4A8"),
                            gradientEnd: Color(hex: "#E8C4A8"),
                            strokeColor: Color(hex: "#C4714A"),
                            action: onGuidedTour
                        )
                        .padding(.bottom, 10)

                        // Tour Libre
                        MenuCardView(
                            icon: AnyView(FreeTourIcon(size: 28)),
                            title: "Tour Libre",
                            gradientStart: Color(hex: "#E6BA62"),
                            gradientEnd: Color(hex: "#E6BA62"),
                            strokeColor: Color(hex: "#C4714A"),
                            action: onFreeTour
                        )
                        .padding(.bottom, 10)

                        // Instrucciones + Términos
                        HStack(spacing: 10) {
                            MenuSquareCardView(
                                icon: AnyView(InstructionsIcon(size: 28)),
                                title: "Instrucciones\nde Uso",
                                gradientStart: Color(hex: "#E5E5C8"),
                                gradientEnd: Color(hex: "#E5E5C8"),
                                strokeColor: Color(hex: "#E6BA62"),
                                action: onInstructions
                            )
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)

                            MenuSquareCardView(
                                icon: AnyView(TermsIcon(size: 28)),
                                title: "Términos y\nCondiciones",
                                gradientStart: Color(hex: "#E5E5C8"),
                                gradientEnd: Color(hex: "#E5E5C8"),
                                strokeColor: Color(hex: "#E6BA62"),
                                action: onTerms
                            )
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        ArchShape()
                            .fill(Color.white)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }

                // Personaje
                VStack(spacing: 0) {
                    Spacer().frame(height: 0)
                    if let url = Bundle.main.url(forResource: "Bienvenida", withExtension: "mp4") {
                        VideoPlayerView(player: AVPlayer(url: url))
                            .frame(height: geo.size.height * 0.33)
                            .onAppear {
                                AVPlayer(url: url).play()
                            }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { setupVideo() }
        .onDisappear { player?.pause() }
    }

    private func setupVideo() {
        guard let url = Bundle.main.url(forResource: "kmju", withExtension: "mp4") else { return }
        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = true
        avPlayer.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }
        avPlayer.play()
        self.player = avPlayer
    }
}

struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> UIView { PlayerUIView(player: player) }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

#Preview { MainMenuView() }
