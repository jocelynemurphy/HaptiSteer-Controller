import SwiftUI
import CoreLocation

struct ProcessingView: View {
    @StateObject var locationManager = LocationTrackerViewController()
    @Environment(\.dismiss) var dismiss // Environment variable to dismiss the modal
    let navRoute: NavRoute // Pass the NavRoute object from ContentView
    
    @State private var currentStepIndex = 0 // Track the current step
    @State private var isNavigating = true // Control the navigation loop
    
    var body: some View {
        ZStack {
            // Background color
            Color(.sRGB, red: 106 / 255, green: 112 / 255, blue: 105 / 255, opacity: 1)
                .ignoresSafeArea()
            
            VStack {
                // "X" button near the top
                HStack {
                    Button("X") {
                        dismiss() // Close the modal
                    }
                    .padding(10)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Spacer() // Push the button to the left
                }
                .padding()
                Spacer() // Push the rest of the content to the center
                
                VStack {
                    Text("🚀🚗 Processing Journey! 🚗🚀")
                        .font(.system(size: 24, weight: .bold))
                        .padding()
                    
                    Text("Additional processing can go here")
                        .padding()
                }
                
                Spacer() // Center the content vertically
            }
        }.onAppear {
            // Start the navigation loop
            startNavigation(navRoute: navRoute)
        }
    }
    
    func getCurrentLocationString () -> String? {
        if let location = locationManager.currentLocation {
            let curr_location = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
            return curr_location
        } else {
            print("Location not available.")
            return nil
        }
    }
    
    func getCurrentLocation() -> CLLocationCoordinate2D {
        if let location = locationManager.currentLocation {
            return location.coordinate
        } else {
            print("Location not available.")
            return CLLocationCoordinate2D()
        }
    }
    
    func startNavigation(navRoute: NavRoute) {
        
        print("Starting navigation...")
        
        
        Task {
            while isNavigating, let currentLocation = locationManager.currentLocation {
                let currentLocation = getCurrentLocation()
                
                // Check distance to current polyline
                var currentStepIndex = navRoute.currentStepIndex
                
                let currentStep = navRoute.getStep(stepIndex: currentStepIndex)
                
                
                // Check distance to the current polyline
                let distanceToPolyline = checkDistanceToPolyline(step: currentStep, location: currentLocation) ?? 0
                
                if distanceToPolyline > 20 {
                    print("off route, recalculating...")
                    // Handle recalculation logic here
                    
                    
                }
                
                // Check distance to the next step
                let distanceToTurn = checkDistanceToTurn(routeStep: currentStep, location: currentLocation) ?? 0
                
                if distanceToTurn < 10 {
                    // Move to the next step
                    currentStepIndex += 1
                    navRoute.advanceStepindex()
                    
                    print("Advancing to step index \(currentStepIndex)")
                    
                    // handle haptic path feedback
                    
                } else {
                    // Handle haptic feedback
                    
                }
                
                // lets pause for one second before running again
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}
