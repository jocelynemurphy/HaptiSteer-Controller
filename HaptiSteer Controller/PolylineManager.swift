//
//  PolylineManager.swift
//  HaptiSteer Controller
//
//  Created by Julia Ju on 2024-11-20.
//

import Foundation
import Polyline
import CoreLocation


func decodePolyline(encodedPolyline: String) -> [LocationCoordinate2D]? {
    let decodedPolyline = Polyline(encodedPolyline: encodedPolyline).coordinates
    return decodedPolyline
}

func distanceFromCoordinateToPolyline(coordinate: CLLocationCoordinate2D, encodedPolyline: String) -> Double? {
    // Decode the polyline
    guard let polyline_coords = decodePolyline(encodedPolyline: encodedPolyline), polyline_coords.count > 1 else {
        print("Invalid or empty polyline.")
        return nil
    }

    var minDistance: Double = .greatestFiniteMagnitude

    // Calculate the shortest distance to each segment of the polyline
    for i in 0..<polyline_coords.count - 1 {
        print("current coord", polyline_coords[i])
        let segmentStart = polyline_coords[i]
        let segmentEnd = polyline_coords[i + 1]
        let distance = distanceFromPoint(coordinate, toLineSegmentBetween: segmentStart, and: segmentEnd)
        minDistance = min(minDistance, distance)
    }

    return minDistance
}

func distanceFromPoint(_ point: CLLocationCoordinate2D, toLineSegmentBetween start: CLLocationCoordinate2D, and end: CLLocationCoordinate2D) -> Double {
    let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
    let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
    let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)

    // Length of the segment
    let segmentLengthSquared = startLocation.distance(from: endLocation)
    if segmentLengthSquared == 0 {
        // Start and end are the same point
        return pointLocation.distance(from: startLocation)
    }

    // Projection factor `t`
    let t = max(0, min(1, ((point.latitude - start.latitude) * (end.latitude - start.latitude) +
                           (point.longitude - start.longitude) * (end.longitude - start.longitude)) /
                        segmentLengthSquared))

    // Find the projection point
    let projection = CLLocationCoordinate2D(
        latitude: start.latitude + t * (end.latitude - start.latitude),
        longitude: start.longitude + t * (end.longitude - start.longitude)
    )

    // Calculate the distance from the point to the projection point
    let projectionLocation = CLLocation(latitude: projection.latitude, longitude: projection.longitude)
    return pointLocation.distance(from: projectionLocation)
}

func checkDistanceToPolyline2 (curr_lat: Double, curr_long: Double, encodedPolyline: String) -> Double? {
    // Example usage:
    let encodedPolyline = "qzihGvpqjNUNK_@K_@k@mB" // Example polyline

    let coordinate = CLLocationCoordinate2D(latitude: curr_lat, longitude: curr_long)
    
    let distance = distanceFromCoordinateToPolyline(coordinate: coordinate, encodedPolyline: encodedPolyline)
   
    print("Shortest distance to polyline: \(String(describing: distance)) meters")
    
    return distance
}

func checkDistanceToPolyline(step: RouteStep, location: CLLocationCoordinate2D) -> Double? {
    let encodedPolyline = step.polylineEncoded
    
    let distance = distanceFromCoordinateToPolyline(coordinate: location, encodedPolyline: encodedPolyline)
    print("Shortest distance to polyline: \(String(describing: distance)) meters")
    
    return distance
}


// Calculate the distance between a location and the turn location of a step
func checkDistanceToTurn(routeStep: RouteStep, location: CLLocationCoordinate2D) -> Double? {

    // convert to this type to use distance method
    let turnLocation = CLLocation(latitude: routeStep.endLocation.lat, longitude: routeStep.endLocation.lng)
    let location = CLLocation(latitude: location.latitude, longitude: location.longitude)

    // Calculate the distance in meters
    let distance = location.distance(from: turnLocation)

    return distance
}

