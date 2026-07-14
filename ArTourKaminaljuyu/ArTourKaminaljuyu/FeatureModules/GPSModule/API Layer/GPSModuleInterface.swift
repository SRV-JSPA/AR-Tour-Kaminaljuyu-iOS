//  GPSModuleInterface.swift
//  ArTourKaminaljuyu
//
//  Created by Jose Pereira on 2/11/26.

import Foundation
import CoreLocation
import Combine

// MARK: - GPSModuleInterface

final class GPSModuleInterface: ObservableObject {

    // MARK: - Instancia compartida
    static let shared = GPSModuleInterface()

    // MARK: - Servicios internos (privados)
    private let locationService  = LocationService()
    private let proximityService = ProximityService()
    private let tourManager      = TourManager()
    private var cancellables     = Set<AnyCancellable>()

    // MARK: - Estado publicado para el módulo AR y UIModule

    @Published private(set) var userLocation: CLLocationCoordinate2D? = nil

    @Published private(set) var userHorizontalAccuracy: Double = 0

    @Published private(set) var userHeading: Double = 0

    @Published private(set) var currentTargetPOI: POILocation? = nil

    @Published private(set) var distanceToTarget: Double = .nan

    @Published private(set) var bearingToTarget: Double = 0

    @Published private(set) var tourState: TourState = .idle

    @Published private(set) var routeCoordinates: [CLLocationCoordinate2D] = []

    @Published private(set) var nearestPOI: ProximityResult? = nil

    // MARK: - Eventos para el módulo AR

    var poiArrivedPublisher: AnyPublisher<POILocation, Never> {
        tourManager.poiArrivedPublisher.eraseToAnyPublisher()
    }

    var tourCompletedPublisher: AnyPublisher<Void, Never> {
        tourManager.tourCompletedPublisher.eraseToAnyPublisher()
    }

    var proximityArrivedPublisher: AnyPublisher<POILocation, Never> {
        proximityService.arrivalPublisher.eraseToAnyPublisher()
    }

    // MARK: - Init
    private init() {
        setupBindings()
    }

    // MARK: - API pública para el módulo AR / UIModule

    func startTracking() {
        locationService.startTracking()
    }

    func stopTracking() {
        locationService.stopTracking()
    }

    func startTour() {
        guard let location = userLocation else { return }
        tourManager.startTour(userLocation: location)
    }

    func advanceToNextPOI() {
        tourManager.advanceToNextPOI()
    }

    func startReturnPhase() {
        tourManager.startReturnPhase()
    }

    func stopTour() {
        tourManager.stopTour()
        proximityService.reset()
    }

    var allPOIs: [POILocation] {
        POIRegistry.shared.pois
    }

    // MARK: - Bindings internos

    private func setupBindings() {

        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self else { return }
                let coord = location.coordinate
                self.userLocation = coord
                self.userHorizontalAccuracy = max(location.horizontalAccuracy, 0)
                self.proximityService.update(
                    userLocation: coord,
                    horizontalAccuracy: location.horizontalAccuracy
                )
                self.tourManager.update(userLocation: coord)
            }
            .store(in: &cancellables)

        locationService.$currentHeading
            .compactMap { $0?.trueHeading }
            .filter { $0 >= 0 }
            .sink { [weak self] heading in
                self?.userHeading = heading
            }
            .store(in: &cancellables)

        tourManager.$state
            .sink { [weak self] state in
                self?.tourState = state
            }
            .store(in: &cancellables)

        tourManager.$currentPOI
            .sink { [weak self] poi in
                self?.currentTargetPOI = poi
            }
            .store(in: &cancellables)

        tourManager.$distanceToTarget
            .sink { [weak self] distance in
                self?.distanceToTarget = distance
            }
            .store(in: &cancellables)

        tourManager.$bearingToTarget
            .sink { [weak self] bearing in
                self?.bearingToTarget = bearing
            }
            .store(in: &cancellables)

        tourManager.$routeCoordinates
            .sink { [weak self] coords in
                self?.routeCoordinates = coords
            }
            .store(in: &cancellables)

        // ProximityService → estado publicado
        proximityService.$nearestPOI
            .sink { [weak self] result in
                self?.nearestPOI = result
            }
            .store(in: &cancellables)
    }
}
