import SwiftUI
import CoreBluetooth
import CoreLocation

func performAPICall(origin: String, destination: String, mode: String) async throws -> DirectionsResponse {
    let apiKey = getApiKey()
    
    let destination = destination.replacingOccurrences(of: " ", with: "+")
    
    let urlString = "https://maps.googleapis.com/maps/api/directions/json"
    guard var urlComponents = URLComponents(string: urlString) else {
        throw URLError(.badURL)
    }
    
    urlComponents.queryItems = [
        URLQueryItem(name: "origin", value: origin),
        URLQueryItem(name: "destination", value: destination),
        URLQueryItem(name: "mode", value: mode),
        URLQueryItem(name: "key", value: apiKey)
    ]
    
    guard let url = urlComponents.url else {
        throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(DirectionsResponse.self, from: data)
    
    if response.status != "OK" {
        throw URLError(.badServerResponse)
    }
    
    return response
}

let maneuverMapping: [String: Int] = [ // mapping of all the different maneuvers to the number of pulses and instruction for pulsing
    // L = -1, M = 0, R = 1. We may send over bluetooth the strings but this will roughly map which pulses.
    "turn-slight-left": 1, // 2 L
    "turn-sharp-left": 2, // 5 L
    "uturn-left": 3, // 3L, 3L, 3L, (repeat until turned around) -> how does it know you've turned around?
    "turn-left": 4, // 5 L
    
    "turn-slight-right": 5, // 2 R
    "turn-sharp-right": 6, // 5 R
    "uturn-right": 7, // 3R, 3R, 3R
    "turn-right": 8, // 5R
    
    "straight": 9, // 2 S
    "ramp-left": 10, // 2 R
    "ramp-right": 11, // 2 R
    "merge": 12, // 2 R or L (is there no merge command for R or L?)
    
    "fork-left": 13, // 2 L
    "fork-right": 14, // 2 R
    "ferry": 15, // N/A
    "ferry-train": 16, // N/A
    
    "roundabout-left": 17, // 3L, 3L, 3L, -> could we know when they should signal right and exit?
    "roundabout-right": 18, // 5 R
    "end-of-road-left": 19, // 2L
    "end-of-road-right": 20, // 2R
    
    "take-exit-left": 21, // 5L
    "take-exit-right": 22, // 5R
    "take-exit": 23, // 5R --> discuss this onw n
    "take-fork-left": 24, // 2L
    "take-fork-right": 25, // 2 R
    
    "head": 26, // ?
    "keep-left": 27, // 1 L
    "keep-right": 28, // 1 R
    "continue": 29 // 1 BOTH
]

func calculateDistance(curr_lat: Double, curr_lng: Double, destination: String) async -> (Double, Double) {
    @ObservedObject var locationManager = LocationTrackerViewController()
    
    @State var apiKey: String = getApiKey()
    
    // find current information
    var starting_location = "\(curr_lat),\(curr_lng)"
    
    print(starting_location)
    // get a directions response
    do {
        let result = try await performAPICall(
            origin: starting_location,
            destination: destination,
            mode: "driving"
        )
        
        if let target_lat = result.routes.first?.legs.first?.steps.first?.endLocation.lat,
           let target_lng = result.routes.first?.legs.first?.steps.first?.endLocation.lng {
            
            print("Target latitude: \(target_lat), Target longitude: \(target_lng)")
            
            let delta_lat = target_lat - curr_lat
            let delta_lng = target_lng - curr_lng
            
            return(delta_lat, delta_lng)
        } else {
            // Handle the case where routes, legs, or steps are missing
            print("No routes, legs, or steps found in the response.")
        }
        //        sendVibrations(result: result);
    } catch {
        print("Error fetching directions: \(error)")
    }
    
    return (-1.0, -1.0)
}

func distFromLocation(curr_lat: Double, curr_lng: Double, destination: String) async -> Double? {
    @ObservedObject var locationManager = LocationTrackerViewController()
    
    @State var apiKey: String = getApiKey()
    
    // find current information
    var starting_location = "\(curr_lat),\(curr_lng)"
    
    do {
        let result = try await performAPICall(
            origin: starting_location,
            destination: destination,
            mode: "driving"
        )
        
        let dist = checkDistanceToPolyline2(curr_lat: curr_lat, curr_long: curr_lng, encodedPolyline: "qzihGvpqjNUNK_@K_@k@mB")
        
        return (dist)
        
    } catch {
        print("Error fetching directions: \(error)")
    }
    
    return 0.0
}



func sendVibrations(result: DirectionsResponse) {
    let steps = result.routes[0].legs[0].steps
    
    for step in steps{
        var distance_remaining = step.distance.value
        let m_per_iteration = 5
        var instruction_given = 0
        
        while distance_remaining > 0 {
            print(distance_remaining, "m remaining.")
            if distance_remaining < 10{
                print("🚨🚨🚨🚨🚨")
            }
            else if distance_remaining < 25{
                print("📳📳📳")
            }
            else if distance_remaining < 100{
                print("...")
                if instruction_given == 0{
                    print("In ", distance_remaining, "m, ", step.maneuver)
                }
                instruction_given += 1
            }
            // else, no vibration, subtract distance
            distance_remaining = distance_remaining - m_per_iteration
        }
        
        print(step.maneuver)
        // no distance remaining, go to the next step.
    }
}

func sendManeuver(maneuver: String?){
    print(maneuver)
}

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var showModal = false
    @State private var navRoute: NavRoute? = nil
    @StateObject var locationManager = LocationTrackerViewController()
    
    @State var message: String = "Waiting for message..."
    @State var destination: String = "330 phillip st waterloo"
    @State var timer: Timer? = nil
    @State var isTimerRunning = 1  // Helper variable to track timer state
    
    @State var apiKey = getApiKey()
    
    
    // calling the api
    var body: some View {
        VStack {
            // BT connection status + retry
            HStack {
                Spacer()
                
                Text(bleManager.isConnected ? "✨Connected to esp32✨" : "Not connected to esp32")
                    .padding(.vertical, 20)
                
                if !bleManager.isConnected {
                    Button(action: {
                        bleManager.reconnect()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16) // Adjust the size as needed
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
        
                Spacer()
            }
            .background(bleManager.isConnected ? Color.green : Color.gray)
            .cornerRadius(8)
            
            Text("HaptiSteer Controller")
                .font(.largeTitle)
                .padding()
            
            Text("Where to?")
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Input text box to set the destination
            TextField("" ,text: $destination)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title3)
            
            
            // Button to test route classes + navigating
            Button(action: {
                Task {
                    if let location = locationManager.currentLocation {
                        let starting_location = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        
                        let directions = try await performAPICall(
                            origin: starting_location,
                            destination: destination,
                            mode: "driving"
                        )
                        navRoute = NavRoute(apiResponse: directions)
                        
                        if navRoute != nil {
                            showModal = true
                        }
                                          
                    } else {
                        message = "theres a problem with the location"
                    }
                }
                
            } ) {
                Text("Start Navigation!")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // Button to call API
            Button(action: {
                Task {
                    do {
                                                
                        let result = try await performAPICall(
                            origin: "engineering+7+university+of+waterloo",
                            destination: destination,
                            mode: "driving"
                        )
                        
                        print(result)
                        
                        // take the set of instructions and output vibrations accordingly
                        sendVibrations(result: result);
                        
                    } catch {
                        print("Error fetching directions: \(error)")
                    }
                }
            }) {
                Text("Get Directions")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            
            Button(action: {
                Task {
                    if let location = locationManager.currentLocation {
                        message = "Current Location: \(location.coordinate.latitude), \(location.coordinate.longitude)"
                    } else {
                        message = "Fetching location..."
                    }}
                
            }) {
                Text("Check Location")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            
            //            // BUTTON TO TOGGLE DISTANCE CALCULATION ON AND OFF
            //            Button(action: {
            //                Task {
            //
            //                        var curr_lat = 0.00
            //                        var curr_lng = 0.00
            //
            //                        if let location = locationManager.currentLocation{
            //                            curr_lat = location.coordinate.latitude
            //                            curr_lng = location.coordinate.longitude
            //
            //                        } else {
            //                            print("Fetching location...")
            //                        }
            //
            //                        await print(calculateDistance(curr_lat: curr_lat, curr_lng: curr_lng)) // this calculates one distance
            //
            //                        message = calculateDistance(curr_lat: curr_lat, curr_lng: curr_lng)
            //
            ////                            if timer == nil {
            ////                                // Start the timer
            ////                                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            ////                                    print("Timer is running")
            ////
            ////                                }
            ////                            } else {
            ////                                // Stop the timer if it's already running
            ////                                timer?.invalidate()
            ////                                timer = nil
            ////                                print("Next Step")
            //                    }
            //
            //            }) {
            //                Text("Start live distance calculation")
            //                    .padding()
            //                    .background(Color.red)
            //                    .foregroundColor(.white)
            //                    .cornerRadius(10)
            //            }
            
            
            // Button to test distance calculation to a polyline
            
//            Button(action: {
//                Task {
//                    if let location = locationManager.currentLocation {
//                        await message = String(
//                            distFromLocation(curr_lat: location.coordinate.latitude, curr_lng: location.coordinate.longitude)!
//                        )
//                    } else {
//                        message = "theres a problem with the location"
//                    }}
//
//            }) {
//                Text("Check distance to polyline")
//                    .padding()
//                    .background(Color.green)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
            
            HStack {
                // Turn-left button
                Button(action: {
                    Task {
                        if bleManager.isConnected {
                            bleManager.sendDirection("turn-left", distance: 5.0)
                        } else {
                            print("ESP32 not connected")
                        }
                       
                    }
                }) {
                    Text("<- Test Left")
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Turn-right button
                Button(action: {
                    Task {
                        if bleManager.isConnected {
                            bleManager.sendDirection("turn-right", distance: 5.0)
                        } else {
                            print("ESP32 not connected")
                        }

                    }
                }) {
                    Text("Test Right ->")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            
            // send messages to be visible in the app
            TextEditor(text: $message)
                .frame(height: 200) // Height of the message box
                .border(Color.gray, width: 1) // Optional border to define the box
                .padding()
        }
        .onAppear {
            bleManager.startScanning()
        }
        // Sheet modifier to present a modal
        .sheet(isPresented: $showModal) {
            if let navRoute = navRoute {
                ProcessingModal(navRoute: navRoute, destination: destination)
            }
        }
    }
}

