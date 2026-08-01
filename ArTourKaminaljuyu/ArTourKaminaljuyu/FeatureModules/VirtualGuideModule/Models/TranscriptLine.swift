//
//  TranscriptLine.swift
//  ArTourKaminaljuyu
//
//  Línea de transcripción con timestamp, usada por VirtualGuideModuleInterface
//  para sincronizar subtítulos con el video que está reproduciendo.
//

import Foundation

struct TranscriptLine: Identifiable {
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double
}
