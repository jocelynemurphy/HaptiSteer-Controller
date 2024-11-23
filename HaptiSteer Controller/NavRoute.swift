//
//  Route.swift
//  HaptiSteer Controller
//
//  Created by Julia Ju on 2024-11-21.
//

import Foundation
import CoreLocation

class NavRoute {
    
    var routeSteps: [RouteStep]
    var currentStepIndex: Int
    
    init(
        apiResponse: DirectionsResponse
    ) {
        self.routeSteps = []
        self.currentStepIndex = 0
        
        
        let steps = apiResponse.routes[0].legs.first?.steps
        self.routeSteps = processPolylineSegments(steps: steps)
        
        
        print ("RouteSteps: \(self.routeSteps)")
    }
    
    func processPolylineSegments(steps: [Step]?) -> [RouteStep] {
        
        var routeSteps = [RouteStep]()
        
        // Adding
        for (index, step) in steps!.enumerated() {
            let polylineDecoded = decodePolyline(encodedPolyline: step.polyline.points)
            let routeStep = RouteStep(
                direction: step.maneuver ?? "straight",
                polylineDecoded: polylineDecoded!,
                polylineEncoded: step.polyline.points,
                stepIndex: index,
                endLocation: step.endLocation
            )
            routeSteps.append(routeStep)
        }
        
        
        return routeSteps
    }
    
    //  Update route with new api response
    func updateRoute(apiResponse: DirectionsResponse) {
        let steps = apiResponse.routes[0].legs.first?.steps
        
        self.currentStepIndex = 0
        self.routeSteps = processPolylineSegments(steps: steps)
    }
    
    func advanceStepindex() {
        self.currentStepIndex += 1
    }
    
    func getStep(stepIndex: Int) -> RouteStep {
        return self.routeSteps[currentStepIndex]
    }
        
}

struct RouteStep {
    let direction : String
    let polylineDecoded : [CLLocationCoordinate2D]
    let polylineEncoded : String
    let stepIndex : Int
    let endLocation: Location
}

