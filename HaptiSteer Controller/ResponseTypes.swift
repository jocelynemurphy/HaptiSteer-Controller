//
//  ResponseTypes.swift
//  HaptiSteer Controller
//
//  Created by Julia Ju on 2024-11-20.
//

import Foundation

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
    let overviewPolyline: PolylineResponse
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
    let polyline: PolylineResponse
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

struct PolylineResponse: Codable {
    let points: String
}

struct NavigationCommand: Codable {
    let maneuver: String
    let distance: Double
}
// __________________________________________________________________________
