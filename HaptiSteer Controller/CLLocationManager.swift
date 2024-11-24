import SwiftUI
import CoreLocation

class LocationTrackerViewController: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    // Observable properties that SwiftUI views can observe
    @Published var currentLocation: CLLocation? = nil
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()  // For foreground usage
        locationManager.requestAlwaysAuthorization()    // For background usage
        locationManager.startUpdatingLocation()
    }
    
    // CLLocationManagerDelegate method to handle location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location  // Update the location property
    }
    
    // CLLocationManagerDelegate method to handle errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error occurred: \(error.localizedDescription)")
    }
    
    // Handle authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission granted.")
            locationManager.startUpdatingLocation()  // Start updating location if permission is granted
        case .denied, .restricted:
            print("Location permission denied or restricted.")
        default:
            print("Location permission status unknown.")
        }
    }
}

class LocationUtils {
    static let locationManager = LocationTrackerViewController()
    
    
    static func getCurrentLocationString() -> String {
        if let location = locationManager.currentLocation {
            return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        } else {
            print("Location not available.")
            return ""
        }
    }

    static func getCurrentLocationCoordinates() -> CLLocationCoordinate2D {
        if let location = locationManager.currentLocation {
            return location.coordinate
        } else {
            print("Location not available.")
            return CLLocationCoordinate2D()
        }
    }
}

