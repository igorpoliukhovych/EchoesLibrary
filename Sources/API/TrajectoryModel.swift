//
//  TrajectoryModel.swift
//  ECHOES
//
//  Created by Josh Kopecek on 13/05/2019.
//  Copyright © 2019 Echoes. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import SwiftyJSON
import CoreLocation

open class TrajectoryModel: Object, Mappable {
    @objc public dynamic var _id = String.randomString(length: 12)
    public var title = List<DescriptionModel>()
    public var desc = List<DescriptionModel>()
    @objc public dynamic var trajectory = ""
    @objc public dynamic var length = 0.0
    @objc public dynamic var duration = 0.0
    @objc public dynamic var pub_status = ""
        
    override public static func primaryKey() -> String? {
        return "_id"
    }
    
    override public static func indexedProperties() -> [String] {
        return ["_id"]
    }
    
    required public convenience init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        _id <- (map["_id"], IdDefaultTransform())
        title <- (map["title"], ListTransform<DescriptionModel>())
        desc <- (map["description"], ListTransform<DescriptionModel>())
        trajectory <- (map["trajectory.coordinates"], JSONFormatterTransform())
        length <- map["length"]
        duration <- map["duration"]
        pub_status <- map["pub_status"]
    }
    
    public var titleText:String {
        get {
            return Helper.i18nise(self.title)
        }
    }
    
    public var descriptionText: String {
        get {
            return Helper.i18nise(self.desc)
        }
    }
    
    public var coordinates: [CLLocationCoordinate2D] {
        get {
            guard let traj = self.trajectory.convertStringToJSON() else { return [] }
            let trajCoords = traj.arrayValue
            var coords:[CLLocationCoordinate2D] = []
            for coord in trajCoords {
                coords.append(CLLocationCoordinate2D(latitude: coord[1].doubleValue, longitude: coord[0].doubleValue))
            }
            return coords
        }
    }

}
