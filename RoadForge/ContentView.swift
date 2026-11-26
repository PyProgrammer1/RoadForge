
import SwiftUI
import MapLibre
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var recenterTrigger = 0

    var body: some View {
        ZStack(alignment: .top) {
            RoadForgeMap(
                location: locationManager.location,
                recenterTrigger: recenterTrigger
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RoadForge")
                            .font(.title2.bold())

                        Text("OpenStreetMap")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Circle()
                            .fill(locationManager.location == nil ? .orange : .green)
                            .frame(width: 10, height: 10)

                        Text(locationManager.location == nil ? "Locating..." : "GPS Active")
                            .font(.caption2)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Spacer()

                HStack {
                    Spacer()

                    Button {
                        locationManager.requestLocation()
                        recenterTrigger += 1
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(.blue, in: Circle())
                            .shadow(radius: 4)
                    }
                }
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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(
            frame: .zero,
            styleURL: URL(string: "https://tiles.openfreemap.org/styles/liberty")
        )

        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        mapView.setCenter(
            CLLocationCoordinate2D(latitude: 38.0, longitude: -97.0),
            zoomLevel: 4,
            animated: false
        )

        mapView.logoView.isHidden = false
        mapView.attributionButton.isHidden = false

        context.coordinator.mapView = mapView

        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        guard let location else { return }

        let coordinator = context.coordinator

        if coordinator.annotation == nil {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = "You are here"

            mapView.addAnnotation(annotation)
            coordinator.annotation = annotation
        } else {
            coordinator.annotation?.coordinate = location.coordinate
        }

        if coordinator.lastRecenterTrigger != recenterTrigger {
            coordinator.lastRecenterTrigger = recenterTrigger

            mapView.setCenter(
                location.coordinate,
                zoomLevel: 16,
                animated: true
            )
        } else if coordinator.lastLocation == nil {
            mapView.setCenter(
                location.coordinate,
                zoomLevel: 16,
                animated: true
            )
        } else {
            mapView.setCenter(
                location.coordinate,
                animated: true
            )
        }

        coordinator.lastLocation = location
    }

    final class Coordinator {
        weak var mapView: MLNMapView?
        var annotation: MLNPointAnnotation?
        var lastLocation: CLLocation?
        var lastRecenterTrigger = 0
    }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
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

        if latest.horizontalAccuracy < 0 || latest.horizontalAccuracy > 100 {
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
