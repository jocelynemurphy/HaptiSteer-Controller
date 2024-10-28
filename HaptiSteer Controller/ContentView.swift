import SwiftUI
import CoreBluetooth

//struct Wrapper: Codable {
//    let items: [Question]
//}

//struct Question: Codable {
//    let score: Int
//    let title: String
//}

//func performAPICall() async throws -> Question {
//    let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json")!
//    let (data, _) = try await URLSession.shared.data(from: url)
//    let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
//    return wrapper.items[0]
//}


// ________________________________________________________________________
// SET UP ALL STRUCTS
// Root structure
struct DirectionsResponse: Codable {
    let geocodedWaypoints: [GeocodedWaypoint]?
    let routes: [Route]
    let status: String
}

struct GeocodedWaypoint: Codable {
    let geocoderStatus: String
    let placeID: String
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case geocoderStatus = "geocoder_status"
        case placeID = "place_id"
        case types
    }
}

struct Route: Codable {
    let bounds: Bounds
    let copyrights: String
    let legs: [Leg]
    let overviewPolyline: Polyline
    let summary: String
    let warnings: [String]
    let waypointOrder: [Int]
    
    enum CodingKeys: String, CodingKey {
        case bounds, copyrights, legs
        case overviewPolyline = "overview_polyline"
        case summary, warnings
        case waypointOrder = "waypoint_order"
    }
}

struct Bounds: Codable {
    let northeast: Location
    let southwest: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct Leg: Codable {
    let distance: TextValue
    let duration: TextValue
    let endAddress: String
    let endLocation: Location
    let startAddress: String
    let startLocation: Location
    let steps: [Step]
    
    enum CodingKeys: String, CodingKey {
        case distance, duration
        case endAddress = "end_address"
        case endLocation = "end_location"
        case startAddress = "start_address"
        case startLocation = "start_location"
        case steps
    }
}

struct Step: Codable {
    let distance: TextValue
    let duration: TextValue
    let endLocation: Location
    let htmlInstructions: String
    let maneuver: String?
    let polyline: Polyline
    let startLocation: Location
    let travelMode: String
    
    enum CodingKeys: String, CodingKey {
        case distance, duration
        case endLocation = "end_location"
        case htmlInstructions = "html_instructions"
        case maneuver
        case polyline, startLocation = "start_location"
        case travelMode = "travel_mode"
    }
}

struct TextValue: Codable {
    let text: String
    let value: Int
}

struct Polyline: Codable {
    let points: String
}
// ________________________________________________________________________

func performAPICall(origin: String, destination: String, mode: String, apiKey: String) async throws -> DirectionsResponse {
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
    
    return response
}

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    // calling the api
    var body: some View {
        VStack {
            Text("HaptiSteer Controller")
                .font(.largeTitle)
                .padding()

            if let message = bleManager.receivedMessage {
                Text("Received Message: \(message)")
                    .padding()
            } else {
                Text("No messages from esp :(")
                    .padding()
            }

            // Button to send a message to ESP32
            Button(action: {
                bleManager.sendMessage("Hello from iPhone")
            }) {
                Text("Send Message to ESP32")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // Button to call API
            Button(action: {
                Task {
//                    try await print(performAPICall())
                    do {
                        let result = try await performAPICall(
                            origin: "engineering+7+university+of+waterloo",
                            destination: "121+columbia+st+w+waterloo",
                            mode: "driving",
                            apiKey: "AIzaSyDb72KOqV8C8PKltAtzuQ8toUYMzuMrBQQ"
                        )
                        
                        let steps = result.routes[0].legs[0].steps
                        
                        for step in steps{
                            print(step.distance, step.maneuver)
                        }
                    } catch {
                        print("Error fetching directions: \(error)")
                    }
                }
            }) {
                Text("Call API")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            bleManager.startScanning()
        }
    }
}

