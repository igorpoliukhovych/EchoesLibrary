//
//  Helper.swift
//  Echoes
//
//  Created by Josh Kopecek on 6/23/15.
//  Copyright (c) 2017 Echoes. All rights reserved.
//
// This class where put common utility functions
import Foundation
import UIKit
import CoreLocation
import SwiftyJSON
import RealmSwift
import GLKit

open class Helper: NSObject {
    
    static let shared: Helper = { return Helper() }()
    
    required override public init() {}
    
    internal func showMessage(title: String, message: String, button: String, controller: UIViewController, handler: ((UIAlertAction) -> Void)? = nil){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: button, style: .default, handler: handler))
        controller.present(alert, animated: true, completion: nil)
    }
    
    /// Degree to radian
    ///
    /// - Parameter angle: Angle in degrees
    /// - Returns: CGFloat Angle in radians
    func degreeToRadian(_ angle:CLLocationDegrees) -> CGFloat {
        
        return (  (CGFloat(angle)) / 180.0 * CGFloat(Double.pi)  )
        
    }
    
    /// Radians to degrees
    ///
    /// - Parameter radian: Angle in radians
    /// - Returns: CLLocationDegrees Angle in degrees
    func radianToDegree(_ radian:CGFloat) -> CLLocationDegrees {
        
        return CLLocationDegrees(  radian * CGFloat(180.0 / Double.pi)  )
        
    }
    
    
    /// Nearest point on polygon
    /// Returns the nearest point on a given polygon for a given point
    ///
    func distanceToPolygon(polygonPath:[CLLocationCoordinate2D], origin:CLLocationCoordinate2D) -> Double {
        var minDist:Double = .greatestFiniteMagnitude
        
        for i in 0...polygonPath.count - 1 {
            let point1:CLLocationCoordinate2D = polygonPath[i]
            // get the next point on the polygonPath, if it's the last point then we loop to the first
            let point2:CLLocationCoordinate2D = (i == polygonPath.count - 1 ? polygonPath[0] : polygonPath[i + 1])
            
            // initiate the vectors as tuples
            let lineSegmentVectorPoint2ToPoint1 = (point2.latitude - point1.latitude, point2.longitude - point1.longitude)
            let lineSegmentVectorOriginToPoint1 = (origin.latitude - point1.latitude, origin.longitude - point1.longitude)
            
            var r = self.dotProduct(left: lineSegmentVectorPoint2ToPoint1, right: lineSegmentVectorOriginToPoint1)
            
            let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            let point1Location = CLLocation(latitude: point1.latitude, longitude: point1.longitude)
            let originToPoint1Magnitude = originLocation.distance(from: point1Location)
            r /= originToPoint1Magnitude
            var dist:Double = 0
            if r < 0 {
                dist = originLocation.distance(from: point1Location)
            } else if r > 1 {
                let point2Location = CLLocation(latitude: point2.latitude, longitude: point2.longitude)
                dist = originLocation.distance(from: point2Location)
            } else {
                let point2Location = CLLocation(latitude: point2.latitude, longitude: point2.longitude)
                let point2ToPoint1Magnitude = point2Location.distance(from: point1Location)
                dist = sqrt(pow(originToPoint1Magnitude, 2) - r * pow(point2ToPoint1Magnitude, 2))
            }
            minDist = (minDist < dist ? minDist : dist)
        }
        return minDist
    }
    
    private func dotProduct(left: (Double, Double), right: (Double, Double)) -> Double {
        return left.0 * right.0 + left.1 * right.1
    }
    
    private func magnitude(_ vector: (Double, Double)) -> Double {
        return sqrt(vector.0*vector.0 + vector.1*vector.1)
    }
    
    internal func locationToParam(location:CLLocationCoordinate2D) -> String {
        return String(location.longitude) + "," + String(location.latitude)
    }
    
    static func i18nise(_ description: List<DescriptionModel>) -> String {
        let titlei18nised = description.first { $0.lang.lowercased() == Locale.current.languageCode?.lowercased() }
        if titlei18nised != nil {
            return titlei18nised!.text
        } else {
            guard let firstDescription = description.first else {
                return ""
            }
            return firstDescription.text
        }
    }
    
    static func i18nise(_ description: [DescriptionModel]) -> String {
        let titlei18nised = description.first { $0.lang.lowercased() == Locale.current.languageCode?.lowercased() }
        if titlei18nised != nil {
            return titlei18nised!.text
        } else {
            guard let firstDescription = description.first else {
                return ""
            }
            return firstDescription.text
        }
    }

    
    static func getMediaProperty(media: List<MediaModel>, for rel: String = "cover-photo") -> String {
        let media = media.first(where: { $0.rel == rel })
        if (media != nil) {
            return media!.href!
        } else {
            return ""
        }
    }
    
    static func getMediaProperty(media: [MediaModel], for rel: String = "cover-photo") -> String {
        let media = media.first(where: { $0.rel == rel })
        if (media != nil) {
            return media!.href!
        } else {
            return ""
        }
    }
    
    static func getCenterCoord(_ locationPoints: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        var x: Float = 0.0
        var y: Float = 0.0
        var z: Float = 0.0
        for point in locationPoints {
            let lat = GLKMathDegreesToRadians(Float(point.latitude))
            let long = GLKMathDegreesToRadians(Float(point.longitude))
            x += cos(lat) * cos(long)
            y += cos(lat) * sin(long)
            z += sin(lat)
        }
        x = x / Float(locationPoints.count)
        y = y / Float(locationPoints.count)
        z = z / Float(locationPoints.count)
        let resultLong = atan2(y, x)
        let resultHyp = sqrt(x * x + y * y)
        let resultLat = atan2(z, resultHyp)
        let result = CLLocationCoordinate2D(latitude: CLLocationDegrees(GLKMathRadiansToDegrees(Float(resultLat))), longitude: CLLocationDegrees(GLKMathRadiansToDegrees(Float(resultLong))))
        
        return result
    }

    static func degreesToRadians(degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    static func radiansToDegrees(radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
    
    static func getBearingBetweenTwoPoints(point1 : CLLocation, point2: CLLocation) -> Double {
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)

        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)

        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let radiansBearing = atan2f(Float(y), Float(x))
        
        return Double(radiansBearing)
    }
    
    static func calculateCoordinate(from coordinate: CLLocationCoordinate2D, onBearing bearingInRadians: Double, atDistance distanceInMetres: Double) -> CLLocationCoordinate2D {
        let coordinateLatitudeInRadians = coordinate.latitude * Double.pi / 180
        let coordinateLongitudeInRadians = coordinate.longitude * Double.pi / 180
        
        let distanceComparedToEarth = distanceInMetres / 6378100
        
        let resultLatitudeInRadians = asin(sin(coordinateLatitudeInRadians) * cos(distanceComparedToEarth) + cos(coordinateLatitudeInRadians) * sin(distanceComparedToEarth) * cos(bearingInRadians));
        let resultLongitudeInRadians = coordinateLongitudeInRadians + atan2(sin(bearingInRadians) * sin(distanceComparedToEarth) * cos(coordinateLatitudeInRadians), cos(distanceComparedToEarth) - sin(coordinateLatitudeInRadians) * sin(resultLatitudeInRadians))
        
        return CLLocationCoordinate2D(latitude: resultLatitudeInRadians * 180 / Double.pi, longitude: resultLongitudeInRadians * 180 / Double.pi)
    }
    
    
    /// Returns the area in square metres of a given north east, south west bounds
    static func areaFromBounds(sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D) -> Double {
        let nw = CLLocation(latitude: sw.latitude, longitude: ne.longitude)
        let se = CLLocation(latitude: ne.latitude, longitude: sw.longitude)
        let swl = CLLocation(latitude: sw.latitude, longitude: sw.longitude)
        let southBoundsLength = se.distance(from: swl)
        let westBoundsLength = nw.distance(from: swl)
        return southBoundsLength * westBoundsLength
    }
}
