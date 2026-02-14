import SwiftUI
import MapKit
import CoreLocation
internal import Combine

struct LocationPickerView: View {
    @Bindable var viewModel: PhotoLibraryViewModel
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.0, longitude: -3.0),
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    ))
    @State private var isSearching = false
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Location"), systemImage: "mappin.and.ellipse")
                .font(.headline)

            // Show existing location from first selected photo
            if let firstPhoto = viewModel.selectedPhotos.first,
               let coord = firstPhoto.originalMetadata?.coordinate {
                HStack {
                    Text("Current:")
                        .foregroundStyle(.secondary)
                    Text(formatCoordinate(coord))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(String(localized: "Search location..."), text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        searchLocation()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Search results
            if !searchResults.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectLocation(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown")
                                        .font(.callout)
                                    if let address = formatAddress(item) {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }

            // Map view with tap-to-select
            ZStack(alignment: .topTrailing) {
                MapReader { proxy in
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                        if let coordinate = viewModel.editingCoordinate {
                            Marker(String(localized: "Selected Location"), coordinate: coordinate)
                                .tint(.red)
                        }
                    }
                    .mapStyle(.standard)
                    .onTapGesture { location in
                        if let coordinate = proxy.convert(location, from: .local) {
                            viewModel.editingCoordinate = coordinate
                            searchText = ""
                            searchResults = []
                        }
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // My Location button
                Button {
                    requestCurrentLocation()
                } label: {
                    Image(systemName: "location.fill")
                        .padding(8)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
                .help(String(localized: "Use my location"))
            }

            // Coordinate display
            if let coordinate = viewModel.editingCoordinate {
                HStack {
                    VStack(alignment: .leading) {
                        Text(formatCoordinate(coordinate))
                            .font(.caption)
                            .fontDesign(.monospaced)
                    }
                    Spacer()
                    Button(String(localized: "Remove")) {
                        viewModel.editingCoordinate = nil
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            // Actions
            HStack {
                Button(String(localized: "Load from Photo")) {
                    if let firstPhoto = viewModel.selectedPhotos.first,
                       let coord = firstPhoto.originalMetadata?.coordinate {
                        viewModel.editingCoordinate = coord
                        updateCamera(for: coord)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button(String(localized: "Apply to Selected")) {
                    viewModel.applyLocationToSelected()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!viewModel.hasSelection || viewModel.editingCoordinate == nil)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                viewModel.editingCoordinate = location.coordinate
                updateCamera(for: location.coordinate)
            }
        }
    }

    private func searchLocation() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let response = response {
                searchResults = Array(response.mapItems.prefix(5))
            }
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        viewModel.editingCoordinate = coordinate
        updateCamera(for: coordinate)
        searchText = item.name ?? ""
        searchResults = []
    }

    private func requestCurrentLocation() {
        locationManager.requestLocation()
    }

    private func updateCamera(for coordinate: CLLocationCoordinate2D) {
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    private func formatCoordinate(_ coord: CLLocationCoordinate2D) -> String {
        let latDir = coord.latitude >= 0 ? "N" : "S"
        let lonDir = coord.longitude >= 0 ? "E" : "W"
        return String(format: "%.6f° %@, %.6f° %@",
                      abs(coord.latitude), latDir,
                      abs(coord.longitude), lonDir)
    }

    private func formatAddress(_ item: MKMapItem) -> String? {
        if let address = item.placemark.title {
            return address
        }
        return nil
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var isRequestingLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private var isAuthorized: Bool {
        let status = manager.authorizationStatus
        // macOS uses .authorized and .authorizedAlways (no .authorizedWhenInUse)
        return status == .authorizedAlways || status == .authorized
    }

    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            isRequestingLocation = true
            manager.requestWhenInUseAuthorization()
        } else if isAuthorized {
            isRequestingLocation = true
            manager.requestLocation()
        } else {
            print("Location access denied. Status: \(status.rawValue)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        isRequestingLocation = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        // Error 0 = kCLErrorLocationUnknown, can retry
        if let clError = error as? CLError, clError.code == .locationUnknown {
            // Location temporarily unavailable, will retry automatically
            return
        }
        isRequestingLocation = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isRequestingLocation && isAuthorized {
            manager.requestLocation()
        }
    }
}

#Preview {
    let vm = PhotoLibraryViewModel()
    return LocationPickerView(viewModel: vm)
        .frame(width: 350)
        .padding()
}
