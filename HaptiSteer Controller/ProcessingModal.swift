import SwiftUI
import CoreLocation

struct ProcessingModal: View {
    @StateObject var locationManager = LocationTrackerViewController()
    @Environment(\.dismiss) var dismiss // Environment variable to dismiss the modal
    
    @State var status: String = "getting status" // Check if the user is on route
    
    let navRoute: NavRoute
    let destination: String
    
    @State private var currentStepIndex = 0 // Track the current step
    @State private var isNavigating = true // Control the navigation loop
    
    var body: some View {
        ZStack {
            // Background color
            Color(.sRGB, red: 106 / 255, green: 112 / 255, blue: 105 / 255, opacity: 1)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("X") {
                        isNavigating = false
                        dismiss() // close the modal
                    }
                    .padding(10)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Spacer() // Push the button to the left
                }
                .padding(.bottom, 40)
                VStack {
                    Text("🚀🚗 Processing Journey! 🚗🚀")
                        .font(.system(size: 24, weight: .bold))
                        .padding()
                    
                    // info on the journey
                    Text("Destination: \(destination)")
                    Text("Step: \(navRoute.currentStepIndex)")
                    Text("Upcoming Maneuver: \(navRoute.getStep(stepIndex: navRoute.currentStepIndex).direction)")
                    Text("Distance to Turning point: \(checkDistanceToTurn(routeStep: navRoute.getStep(stepIndex: navRoute.currentStepIndex), location: LocationUtils.getCurrentLocationCoordinates()) ?? 0)")
                    
                    Text("Distance to polyline: \(checkDistanceToPolyline(step: navRoute.getStep(stepIndex: navRoute.currentStepIndex), location: LocationUtils.getCurrentLocationCoordinates()) ?? 0)")
                    Text("Status: \(status)")
                }
                
                Spacer()
            }
        }
        .onAppear {
            // immediately start navigation when the modal appears
            startNavigation(navRoute: navRoute)
        }
        .onDisappear {
            // stop navigation when the modal is swiped away
            isNavigating = false
        }
    }
    
    func resetRoute() async {
        
        //    UNCOMMENT WHEN WE ARE READY TO TEST
        
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
            while isNavigating{
                let currentLocation = LocationUtils.getCurrentLocationCoordinates()
                
                // Check distance to current polyline
                var currentStepIndex = navRoute.currentStepIndex
                
                let currentStep = navRoute.getStep(stepIndex: currentStepIndex)
                
                // Check distance to the current polyline
                let distanceToPolyline = checkDistanceToPolyline(step: currentStep, location: currentLocation) ?? 0
                
                if distanceToPolyline > 25 {
                    print("Off route, recalculating...")
                    // Handle recalculation logic here
                    status = "Off route, recalculating..."
                    await resetRoute()
                } else {
                    status = "On route :D"
                }
                
                // Check distance to the next step
                let distanceToTurn = checkDistanceToTurn(routeStep: currentStep, location: currentLocation) ?? 0
                
                if distanceToTurn < 15 {
                    // Move to the next step
                    currentStepIndex += 1
                    navRoute.advanceStepindex()
                    
                    print("Advancing to step index \(currentStepIndex)")
                    
                    status = "Advancing to step index \(currentStepIndex)"
                } else {
                    // Handle haptic feedback
            
                }
                
                // Stopping case with case
                if currentStepIndex >= navRoute.routeSteps.count {
                    print("End of route reached.")
                    status = "End of route reached"
                    isNavigating = false
                    return
                }
                
                // Pause for half a second
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
}
