```swift
import SwiftUI
import MapLibre
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack(alignment: .top) {
            RoadForgeMap(location: locationManager.location)
                .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RoadForge")
                            .font(.title2.bold())

                        Text("OpenStreetMap")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        locationManager.requestLocation()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(.blue, in: Circle())
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding()
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
}

struct RoadForgeMap: UIViewRepresentable {
    var location: CLLocation?

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

        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        guard let location else { return }

        mapView.setCenter(
            location.coordinate,
            zoomLevel: 15,
            animated: true
        )
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
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        location = latest
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Location error: \(error.localizedDescription)")
    }
}
```
