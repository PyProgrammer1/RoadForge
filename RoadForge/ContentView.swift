
import SwiftUI
import MapLibre
import CoreLocation

struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

final class PlaceSearchModel: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let geocoder = CLGeocoder()

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else { return }

        geocoder.cancelGeocode()
        isSearching = true
        errorMessage = nil
        results = []

        geocoder.geocodeAddressString(trimmed) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self else { return }

                self.isSearching = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                let mapped = (placemarks ?? []).compactMap { placemark -> SearchResult? in
                    guard let location = placemark.location else {
                        return nil
                    }

                    let name = placemark.name ?? trimmed

                    let addressParts = [
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }

                    let address = addressParts.joined(separator: ", ")

                    return SearchResult(
                        name: name,
                        address: address,
                        coordinate: location.coordinate
                    )
                }

                self.results = mapped

                if mapped.isEmpty {
                    self.errorMessage = "No places found."
                }
            }
        }
    }

    func clear() {
        geocoder.cancelGeocode()
        results = []
        errorMessage = nil
        isSearching = false
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchModel = PlaceSearchModel()

    @State private var searchText = ""
    @State private var recenterTrigger = 0
    @State private var zoomInTrigger = 0
    @State private var zoomOutTrigger = 0
    @State private var compassTrigger = 0
    @State private var destinationTrigger = 0
    @State private var selectedDestination: CLLocationCoordinate2D?

    var body: some View {
        ZStack(alignment: .top) {
            RoadForgeMap(
                location: locationManager.location,
                recenterTrigger: recenterTrigger,
                zoomInTrigger: zoomInTrigger,
                zoomOutTrigger: zoomOutTrigger,
                compassTrigger: compassTrigger,
                destination: selectedDestination,
                destinationTrigger: destinationTrigger
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Search
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search places or addresses", text: $searchText)
                            .submitLabel(.search)
                            .onSubmit {
                                searchModel.search(searchText)
                            }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchModel.clear()
                                selectedDestination = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            searchModel.search(searchText)
                        } label: {
                            Image(systemName: "arrow.forward.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Search results
                if searchModel.isSearching ||
                    !searchModel.results.isEmpty ||
                    searchModel.errorMessage != nil {

                    VStack(spacing: 0) {
                        if searchModel.isSearching {
                            HStack {
                                ProgressView()

                                Text("Searching...")
                                    .font(.subheadline)
                            }
                            .padding()
                        }

                        if let error = searchModel.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                        }

                        ForEach(searchModel.results) { result in
                            Button {
                                selectedDestination = result.coordinate
                                destinationTrigger += 1

                                searchModel.clear()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.title3)
                                        .foregroundStyle(.blue)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)

                                        Text(result.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider()
                        }
                    }
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                // Status
                if searchModel.results.isEmpty &&
                    searchModel.errorMessage == nil &&
                    !searchModel.isSearching {

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RoadForge")
                                .font(.title2.bold())

                            Text("OpenStreetMap")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 5) {
                            Circle()
                                .fill(
                                    locationManager.location == nil
                                    ? .orange : .green
                                )
                                .frame(width: 10, height: 10)

                            Text(
                                locationManager.location == nil
                                ? "Locating..." : "GPS Active"
                            )
                            .font(.caption2)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }

                Spacer()

                // Map controls
                VStack(spacing: 14) {
                    Button {
                        compassTrigger += 1
                    } label: {
                        Image(systemName: "compass")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding(14)
                            .background(.regularMaterial, in: Circle())
                    }

                    VStack(spacing: 0) {
                        Button {
                            zoomInTrigger += 1
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .frame(width: 48, height: 48)
                        }

                        Divider()
                            .frame(width: 30)

                        Button {
                            zoomOutTrigger += 1
                        } label: {
                            Image(systemName: "minus")
                                .font(.title2.bold())
                                .frame(width: 48, height: 48)
                        }
                    }
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button {
                        recenterTrigger += 1
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(.blue, in: Circle())
                    }

                    Text("Recenter")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
}

struct RoadForgeMap: UIViewRepresentable {
    var location: CLLocation?
    var recenterTrigger: Int
    var zoomInTrigger: Int
    var zoomOutTrigger: Int
    var compassTrigger: Int
    var destination: CLLocationCoordinate2D?
    var destinationTrigger: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(
            frame: .zero,
            styleURL: URL(
                string: "https://tiles.openfreemap.org/styles/liberty"
            )
        )

        mapView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        mapView.setCenter(
            CLLocationCoordinate2D(
                latitude: 38.0,
                longitude: -97.0
            ),
            zoomLevel: 4,
            animated: false
        )

        mapView.logoView.isHidden = false
        mapView.attributionButton.isHidden = false

        context.coordinator.mapView = mapView
        context.coordinator.following = true

        mapView.delegate = context.coordinator

        if let gestures = mapView.gestureRecognizers {
            for gesture in gestures {
                if let pan = gesture as? UIPanGestureRecognizer {
                    pan.addTarget(
                        context.coordinator,
                        action: #selector(
                            Coordinator.handlePan(_:)
                        )
                    )
                }
            }
        }

        return mapView
    }

    func updateUIView(
        _ mapView: MLNMapView,
        context: Context
    ) {
        let coordinator = context.coordinator

        // GPS marker
        if let location {
            if coordinator.annotation == nil {
                let annotation = MLNPointAnnotation()
                annotation.coordinate = location.coordinate
                annotation.title = "You are here"

                mapView.addAnnotation(annotation)
                coordinator.annotation = annotation
            } else {
                coordinator.annotation?.coordinate =
                    location.coordinate
            }

            if coordinator.lastLocation == nil {
                mapView.setCenter(
                    location.coordinate,
                    zoomLevel: 16,
                    animated: true
                )
            } else if coordinator.following {
                mapView.setCenter(
                    location.coordinate,
                    animated: true
                )
            }

            coordinator.lastLocation = location
        }

        // Destination pin
        if coordinator.lastDestinationTrigger != destinationTrigger {
            coordinator.lastDestinationTrigger = destinationTrigger

            if let destination {
                if coordinator.destinationAnnotation == nil {
                    let annotation = MLNPointAnnotation()
                    annotation.title = "Destination"
                    annotation.coordinate = destination

                    mapView.addAnnotation(annotation)
                    coordinator.destinationAnnotation = annotation
                } else {
                    coordinator.destinationAnnotation?.coordinate =
                        destination
                }

                coordinator.following = false

                mapView.setCenter(
                    destination,
                    zoomLevel: 15,
                    animated: true
                )
            }
        }

        // Recenter
        if coordinator.lastRecenterTrigger != recenterTrigger {
            coordinator.lastRecenterTrigger = recenterTrigger

            if let location {
                coordinator.following = true

                mapView.setCenter(
                    location.coordinate,
                    zoomLevel: 16,
                    animated: true
                )
            }
        }

        // Zoom in
        if coordinator.lastZoomInTrigger != zoomInTrigger {
            coordinator.lastZoomInTrigger = zoomInTrigger

            mapView.setZoomLevel(
                mapView.zoomLevel + 1,
                animated: true
            )
        }

        // Zoom out
        if coordinator.lastZoomOutTrigger != zoomOutTrigger {
            coordinator.lastZoomOutTrigger = zoomOutTrigger

            mapView.setZoomLevel(
                mapView.zoomLevel - 1,
                animated: true
            )
        }

        // Compass
        if coordinator.lastCompassTrigger != compassTrigger {
            coordinator.lastCompassTrigger = compassTrigger

            mapView.setDirection(
                0,
                animated: true
            )
        }
    }

    final class Coordinator: NSObject, MLNMapViewDelegate {
        weak var mapView: MLNMapView?

        var annotation: MLNPointAnnotation?
        var destinationAnnotation: MLNPointAnnotation?
        var lastLocation: CLLocation?

        var lastRecenterTrigger = 0
        var lastZoomInTrigger = 0
        var lastZoomOutTrigger = 0
        var lastCompassTrigger = 0
        var lastDestinationTrigger = 0

        var following = true

        @objc func handlePan(
            _ gesture: UIPanGestureRecognizer
        ) {
            if gesture.state == .began {
                following = false
            }
        }
    }
}

final class LocationManager:
    NSObject,
    ObservableObject,
    CLLocationManagerDelegate
{
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus =
        .notDetermined

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        if authorizationStatus == .authorizedWhenInUse ||
            authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        authorizationStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }

        if latest.horizontalAccuracy < 0 ||
            latest.horizontalAccuracy > 100 {
            return
        }

        location = latest
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Location error: \(error.localizedDescription)")
    }
}
