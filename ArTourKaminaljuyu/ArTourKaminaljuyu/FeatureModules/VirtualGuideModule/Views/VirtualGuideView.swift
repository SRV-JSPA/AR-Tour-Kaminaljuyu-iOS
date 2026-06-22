//
//  VirtualGuideView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 21/06/26.
//

import SwiftUI
import AVFoundation
import Combine

struct VirtualGuideView: View {
    @State private var player: AVPlayer? = nil
    @State private var isVisible: Bool = false
    @State private var cancellables = Set<AnyCancellable>()

    private let videoMap: [String: String] = [
        "monticulo_6": "M CII 6_final",
        "acropolis": "Acrópolis CII 4_final",
        "monticulo_3": "M CII 3_final"
    ]

    var body: some View {
        ZStack {
            if isVisible, let player = player {
                VideoPlayerView(player: player, gravity: .resizeAspect)
                    .frame(width: 280, height: 420)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            setupEventListeners()
        }
        .onDisappear {
            cancellables.removeAll()
            player?.pause()
        }
    }

    private func setupEventListeners() {
        EventBus.shared.publisher
            .receive(on: DispatchQueue.main)
            .sink { event in
                print("[VirtualGuide] evento recibido: \(event)")
                switch event {
                case .poiReached(let poiId):
                    print("[VirtualGuide] POI alcanzado: \(poiId)")
                    if let videoName = videoMap[poiId] {
                        print("[VirtualGuide] reproduciendo: \(videoName)")
                        playVideo(named: videoName)
                    } else {
                        print("[VirtualGuide] no hay video mapeado para: \(poiId)")
                    }
                case .tourCompleted:
                    playVideo(named: "Despedida_final")
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func playVideo(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mov") else {
            print("[VirtualGuide] Video no encontrado: \(name)")
            return
        }

        player?.pause()
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        isVisible = true

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                self.isVisible = false
                self.player = nil
            }
        }

        newPlayer.play()
    }
}
