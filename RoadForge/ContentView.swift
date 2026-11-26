import SwiftUI
import Combine
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            MapPlaceholder()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RoadForge")
                            .font(.title2.bold())

                        Text("Custom navigation")
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

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Where to?")
                        .font(.title.bold())

                    Text("Navigation will be available in a future update.")
                        .foregroundStyle(.secondary)

                    Button {
                        locationManager.requestLocation()
                    } label: {
                        Label("Locate Me", systemImage: "location")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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

struct MapPlaceholder: View {
    var body: some View {
        ZStack {
            Color(red: 0.88, green: 0.91, blue: 0.87)

            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.25))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.6),
                        control1: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4),
                        control2: CGPoint(x: geometry.size.width * 0.6, y: geometry.size.height * 0.15)
                    )

                    path.move(to: CGPoint(x: geometry.size.width * 0.2, y: 0))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height),
                        control1: CGPoint(x: geometry.size.width * 0.4, y: geometry.size.height * 0.3),
                        control2: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.7)
                    )
                }
                .stroke(.white, style: StrokeStyle(lineWidth: 18, lineCap: .round))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.25))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.6),
                        control1: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4),
                        control2: CGPoint(x: geometry.size.width * 0.6, y: geometry.size.height * 0.15)
                    )
                }
                .stroke(.gray.opacity(0.3), lineWidth: 2)
            }

            VStack {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.blue)

                Text("Map engine coming soon")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .ignoresSafeArea()
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
