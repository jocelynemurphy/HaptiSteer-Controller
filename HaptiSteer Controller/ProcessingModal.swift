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
    
    // testing related variables
    @State private var testingMode: Bool = true
    @State private var fakeManeuver: String = ""
    @State private var fakeDistRemaining: Double = 0
    
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
                        
                        Text("Step: \(navRoute.currentStepIndex)/ \(navRoute.routeSteps.count)")
                        
                        Text("Upcoming Maneuver: \(navRoute.getStep(stepIndex: navRoute.nextStepIndex).direction)")
                        
                        Text("Distance to turning point: \(checkDistanceToTurn(routeStep: navRoute.getStep(stepIndex: navRoute.currentStepIndex), location: LocationUtils.getCurrentLocationCoordinates()) ?? 0)")
                        
                        Text("Distance to polyline: \(checkDistanceToPolyline(step: navRoute.getStep(stepIndex: navRoute.currentStepIndex), location: LocationUtils.getCurrentLocationCoordinates()) ?? 0)")
                        
                        Text("Status: \(status)")
                    } else {
                        Text("Upcoming Maneuver: \(fakeManeuver)")
                        Text("Distance to turning point: \(fakeDistRemaining)")
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
                if distanceToTurn < 25 {
                    // send direction to BLE
                    bleManager.sendDirection(currentStep.direction, distance: distanceToTurn)
                    
                    currentStepIndex += 1
                    navRoute.advanceStepindex()
                    print("Advancing to step index \(currentStepIndex)")
                    status = "Advancing to step index \(currentStepIndex), \(navRoute.getStep(stepIndex: currentStepIndex).direction)"
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                }
                
                if currentStepIndex == navRoute.routeSteps.count || !isNavigating {
                    print("End of route reached.")
                    status = "End of route reached 😎"
                    isNavigating = false
                    
                    return
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
    func startTestNavigation() {
        print("Starting test navigation...")
        
        // Define fake steps with maneuvers. Each step is a 100 meter segment
        let fakeSteps: [(maneuver: String, distance: Double)] = [
            ("turn-left", 100.0),
            ("turn-right", 100.0),
            ("straight", 100.0),
            ("turn-left", 100.0)
        ]
                
        Task {
            for (maneuver, totalDistance) in fakeSteps {
                guard isNavigating else {
                    print("Navigation stopped.")
                    break
                }
                
                var distanceRemaining = totalDistance
                let mPerIteration = 15.0  // Decrement per iteration
                
                fakeManeuver = maneuver
                
                while distanceRemaining > 0 {
                    print("\(distanceRemaining)m remaining for maneuver: \(fakeManeuver)")
                    fakeDistRemaining = distanceRemaining
                    
                    if distanceRemaining < 25 {
                        print("Sending maneuver to BLE: \(fakeManeuver) at \(fakeDistRemaining)m remaining.")
                        bleManager.sendDirection(fakeManeuver, distance: fakeDistRemaining)
                        
                        break
                    }
                    
                    // decrement distance remaining to simulate movement
                    distanceRemaining -= mPerIteration
                    if distanceRemaining < 0 { distanceRemaining = 0 } // prevent negative distance
                    
                    // delay between iterations
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 0.5 second
                }
                
                status = "Maneuver completed: \(fakeManeuver)"
                
                // Optional: Add a brief pause between maneuvers
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
            
            // After all steps are done, end navigation
            print("All steps completed.")
            
            sen
            status = "Test route completed"
            isNavigating = false
        }
    }
}
