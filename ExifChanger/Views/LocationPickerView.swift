import SwiftUI
import MapKit
import CoreLocation
import Combine

struct LocationPickerView: View {
    @Bindable var viewModel: PhotoLibraryViewModel
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.0, longitude: -3.0),
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )
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

            // Map view - click to set location
            Text(String(localized: "Click on map to set location"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            ZStack(alignment: .topTrailing) {
                ClickableMapView(
                    region: mapRegion,
                    photoLocations: photosWithLocations.compactMap { $0.originalMetadata?.coordinate },
                    editingCoordinate: viewModel.editingCoordinate,
                    onTap: { coordinate in
                        viewModel.editingCoordinate = coordinate
                        searchText = ""
                        searchResults = []
                    },
                    onRegionChange: { newRegion in
                        DispatchQueue.main.async {
                            mapRegion = newRegion
                        }
                    }
                )
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
        .onChange(of: viewModel.selectedPhotoIDs) {
            fitMapToSelectedPhotos()
        }
        .onAppear {
            fitMapToSelectedPhotos()
        }
    }

    // Photos with GPS locations among selected
    private var photosWithLocations: [PhotoItem] {
        viewModel.selectedPhotos.filter { $0.originalMetadata?.coordinate != nil }
    }

    private func fitMapToSelectedPhotos() {
        let coordinates = photosWithLocations.compactMap { $0.originalMetadata?.coordinate }
        guard !coordinates.isEmpty else { return }

        if coordinates.count == 1 {
            // Single photo - zoom to its location
            updateCamera(for: coordinates[0])
        } else {
            // Multiple photos - fit all markers
            let minLat = coordinates.map { $0.latitude }.min()!
            let maxLat = coordinates.map { $0.latitude }.max()!
            let minLon = coordinates.map { $0.longitude }.min()!
            let maxLon = coordinates.map { $0.longitude }.max()!

            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            let span = MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
                longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
            )

            mapRegion = MKCoordinateRegion(center: center, span: span)
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
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
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
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        isRequestingLocation = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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

// MARK: - Clickable Map View (NSViewRepresentable)

struct ClickableMapView: NSViewRepresentable {
    var region: MKCoordinateRegion
    var photoLocations: [CLLocationCoordinate2D]
    var editingCoordinate: CLLocationCoordinate2D?
    var onTap: (CLLocationCoordinate2D) -> Void
    var onRegionChange: (MKCoordinateRegion) -> Void

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)

        // Add click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        clickGesture.numberOfClicksRequired = 1
        mapView.addGestureRecognizer(clickGesture)

        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        // Update region if significantly different
        let currentCenter = mapView.region.center
        let newCenter = region.center
        let distance = abs(currentCenter.latitude - newCenter.latitude) + abs(currentCenter.longitude - newCenter.longitude)

        if distance > 0.0001 {
            mapView.setRegion(region, animated: true)
        }

        // Update annotations
        mapView.removeAnnotations(mapView.annotations)

        // Add photo location annotations (blue)
        for coord in photoLocations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            annotation.title = "Photo"
            mapView.addAnnotation(annotation)
        }

        // Add editing coordinate annotation (red)
        if let editCoord = editingCoordinate {
            let annotation = EditingAnnotation()
            annotation.coordinate = editCoord
            annotation.title = String(localized: "New Location")
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ClickableMapView

        init(_ parent: ClickableMapView) {
            self.parent = parent
        }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onTap(coordinate)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.onRegionChange(mapView.region)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let identifier = annotation is EditingAnnotation ? "editing" : "photo"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                view?.annotation = annotation
            }

            if annotation is EditingAnnotation {
                view?.markerTintColor = .systemRed
            } else {
                view?.markerTintColor = .systemBlue
            }

            return view
        }
    }
}

// Custom annotation class to distinguish editing marker
class EditingAnnotation: MKPointAnnotation {}

#Preview {
    let vm = PhotoLibraryViewModel()
    return LocationPickerView(viewModel: vm)
        .frame(width: 350)
        .padding()
}
