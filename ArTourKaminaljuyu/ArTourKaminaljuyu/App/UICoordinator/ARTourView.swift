//
//  ARTourView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 16/05/26.
//

//
//  ARTourView.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 16/05/26.
//

import SwiftUI
import Combine
import CoreLocation

struct ARTourView: View {
    @State private var cancellables = Set<AnyCancellable>()
    @StateObject private var guideVM = VirtualGuideViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewControllerWrapper()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                Group {
                    if guideVM.player != nil && guideVM.showsVideo {
                        VirtualGuideView(viewModel: guideVM)
                    } else {
                        MapOverlayView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.28)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            guideVM.start()
            GPSModuleInterface.shared.startTracking()

            GPSModuleInterface.shared.proximityArrivedPublisher
                .sink { poi in
                    print("[EventBus] POI alcanzado: \(poi.id)")
                    EventBus.shared.publish(.poiReached(poiId: poi.id))
                    AppStateManager.shared.setActivePOI(poi.id)
                }
                .store(in: &cancellables)

            GPSModuleInterface.shared.$userLocation
                .compactMap { $0 }
                .combineLatest(GPSModuleInterface.shared.$userHeading)
                .sink { location, heading in
                    EventBus.shared.publish(.locationUpdated(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        heading: heading
                    ))
                }
                .store(in: &cancellables)
        }
        .onDisappear {
            guideVM.stop()
        }
    }
}
