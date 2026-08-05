//
//  VirtualGuideView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 21/06/26.
//
//  Views del VirtualGuideModule. La lógica del módulo vive en
//  VirtualGuideModuleInterface (API Layer); estas views solo hacen binding
//  reactivo al estado publicado.
//

import SwiftUI
import AVFoundation
import Combine

struct VirtualGuideView: View {
    @ObservedObject var viewModel: VirtualGuideModuleInterface

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                HStack(spacing: 0) {
                    if viewModel.showsTranscript {
                        TranscriptPanel(viewModel: viewModel)
                            .frame(width: geo.size.width * 0.45)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    ZStack {
                        Color.black
                        if let player = viewModel.player {
                            VideoPlayerView(player: player, gravity: .resizeAspect, autoPlay: true)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.showsTranscript)
            }
        }
    }
}

struct TranscriptToggleButton: View {
    @ObservedObject var viewModel: VirtualGuideModuleInterface

    var body: some View {
        Button {
            viewModel.toggleTranscript()
        } label: {
            Image(systemName: viewModel.showsTranscript ? "text.bubble.fill" : "text.bubble")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct TranscriptPanel: View {
    @ObservedObject var viewModel: VirtualGuideModuleInterface

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    Spacer().frame(height: 8)
                    ForEach(Array(viewModel.transcriptLines.enumerated()), id: \.element.id) { i, line in
                        Text(line.text)
                            .font(.system(
                                size: i == viewModel.currentLineIndex ? 13 : 11,
                                weight: i == viewModel.currentLineIndex ? .bold : .regular
                            ))
                            .foregroundColor(
                                i == viewModel.currentLineIndex
                                    ? Color(red: 0.82, green: 0.36, blue: 0.20)
                                    : Color.white.opacity(0.55)
                            )
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(i)
                            .padding(.horizontal, 10)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.currentLineIndex)
                    }
                    Spacer().frame(height: 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.92))
            .onChange(of: viewModel.currentLineIndex) { newIndex in
                guard newIndex >= 0 else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
}
