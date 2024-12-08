import SwiftUI
import CoreLocation

struct ProcessingModal: View {
    @StateObject var locationManager = LocationTrackerViewController()
    @EnvironmentObject var bleManager: BLEManager
    @Environment(\.dismiss) var dismiss
    
    @State var status: String = "getting status"
    let navRoute: NavRoute
    let destination: String
    
    @State private var currentStepIndex = 0
    @State private var isNavigating = true
    
    // set to true to test the navigation with fake steps
    @State private var testingMode: Bool = true
    
    var body: some View {
        ZStack {
            Color(.sRGB, red: 106 / 255, green: 112 / 255, blue: 105 / 255, opacity: 1)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("X") {
                        isNavigating = false
                        dismiss()
                    }
                    .padding(10)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
                
                VStack {
                    Text("🚀🚗 Processing Journey! 🚗🚀")
                        .font(.system(size: 24, weight: .bold))
                        .padding()
                    
                    
                    if !testingMode {
                        Text("Destination: \(destination)")
                        Text("Step: \(navRoute.currentStepIndex)")
                        Text("Upcoming Maneuver: \(navRoute.getStep(stepIndex: navRoute.currentStepIndex).direction)")
                        Text("Distance to Turning point: \(checkDistanceToTurn(routeStep: navRoute.getStep(stepIndex: navRoute.currentStepIndex), location: LocationUtils.getCurrentLocationCoordinates()) ?? 0)")
                        
                        Text("Distance to polyline: \(checkDistanceToPolyline(step: navRoute.getStep(stepIndex: navRoute.currentStepIndex), location: LocationUtils.getCurrentLocationCoordinates()) ?? 0)")
                        Text("Status: \(status)")
                    } else {
                        Text("Destination: \(destination)")
                        Text("Status: \(status)")
                    }

                }
                
                Spacer()
            }
        }
        .onAppear {
            // Decide which navigation mode to start based on testingMode
            if testingMode {
                startTestNavigation()
            } else {
                startNavigation(navRoute: navRoute)
            }
        }
        .onDisappear {
            isNavigating = false
        }
    }
    
    func resetRoute() async {
        let currentLocation = LocationUtils.getCurrentLocationString()
        do {
            let result = try await performAPICall(
                origin: currentLocation,
                destination: destination,
                mode: "driving"
            )
            navRoute.updateRoute(apiResponse: result)
        } catch {
            print("Error: \(error)")
        }
    }
    
    func startNavigation(navRoute: NavRoute) {
        print("Starting navigation...")
        print(navRoute.routeSteps)
        
        Task {
            while isNavigating {
                let currentLocation = LocationUtils.getCurrentLocationCoordinates()
                var currentStepIndex = navRoute.currentStepIndex
                let currentStep = navRoute.getStep(stepIndex: currentStepIndex)
                
                let distanceToPolyline = checkDistanceToPolyline(step: currentStep, location: currentLocation) ?? 0
                if distanceToPolyline > 25 {
                    print("Off route, recalculating...")
                    status = "Off route, recalculating..."
                    await resetRoute()
                } else {
                    status = "On route :D"
                }
                
                let distanceToTurn = checkDistanceToTurn(routeStep: currentStep, location: currentLocation) ?? 0
                if distanceToTurn < 15 {
                    currentStepIndex += 1
                    navRoute.advanceStepindex()
                    print("Advancing to step index \(currentStepIndex)")
                    status = "Advancing to step index \(currentStepIndex)"
                }
                
                if currentStepIndex >= navRoute.routeSteps.count {
                    print("End of route reached.")
                    status = "End of route reached"
                    isNavigating = false
                    return
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
    func startTestNavigation() {
        print("Starting test navigation...")
        
        let fakeSteps: [(maneuver: String, distance: Double)] = [
            ("turn-left", 5.0),
            ("turn-right", 10.0),
            ("straight", 7.5),
            ("turn-left", 3.0)
        ]
                
        Task {
            for (maneuver, distance) in fakeSteps {
                guard isNavigating else { break }
                
                
                status = "step: \(maneuver) with distance \(distance)"
      
                bleManager.sendDirection(maneuver, distance: distance)
                
                // Simulate some delay between steps
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second
            }
            
            // After steps are done, end navigation
            print("All  steps completed.")
            status = "Test route completed"
            isNavigating = false
        }
    }
}
