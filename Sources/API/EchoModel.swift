//
//  Echo.swift
//  Duckworth Awakenings
//
//  Created by Josh Kopecek on 28/11/16.
//  Copyright © 2016 Echoes XYZ. All rights reserved.
//

import Foundation
import CoreLocation
import RealmSwift
import ObjectMapper
import SwiftyJSON

open class EchoModel: Object, Mappable {
    @objc public dynamic var _id = ""
    
    var title = List<DescriptionModel>()
    var desc = List<DescriptionModel>()
    @objc public dynamic var slug = ""
    
    @objc public dynamic var owner = ""
    
    @objc public dynamic var trigger = ""
    @objc public dynamic var logic = ""
    
    @objc public dynamic var collection_id = ""
    @objc public dynamic var radius = 0.0
    var media = List<MediaModel>()
    @objc public dynamic var tags = ""
    @objc public dynamic var polygon = ""
    @objc public dynamic var loc = ""
    @objc public dynamic var shape = ""
    @objc public dynamic var hide_zone = false
    @objc public dynamic var hide_player = false
    @objc public dynamic var layer = 0
    @objc public dynamic var updated_at = NSDate()
    @objc public dynamic var creation_date = NSDate()
    @objc public dynamic var imageData = Data()
    var metadata = List<MetadataModel>()
    
    @objc public dynamic var localCoverPath:String = ""
    @objc public dynamic var isDownloaded = false
    var elements = List<ElementModel>()
    @objc public dynamic var lat: Float = 0.0
    @objc public dynamic var lng: Float = 0.0
    
    @objc public dynamic var spatialization: Bool = false
    
    // beacon
    @objc public dynamic var prox_uuid = ""
    @objc public dynamic var prox_trig_dist: Float = 0.0
    @objc public dynamic var prox_major_id: Int = 0
    @objc public dynamic var prox_minor_id: Int = 0
    
    @objc public dynamic var size_bytes = 0
    
    @objc dynamic var will_delete = false
    
    let collections = LinkingObjects(fromType: CollectionModel.self, property: "echoes")
    
    var titleText: String {
        get {
            return Helper.i18nise(self.title)
        }
    }
    var descriptionText: String {
        get {
            return Helper.i18nise(self.desc)
        }
    }
    var coverHref: String {
        get {
            guard localCoverPath != "" else {
                return Helper.getMediaProperty(media: self.media)
            }
            return localCoverPath
        }
    }
    
    override public static func primaryKey() -> String? {
        return "_id"
    }
    
    override public static func indexedProperties() -> [String] {
        return ["_id"]
    }
    
    required convenience public init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        _id <- map["_id"]
        
        desc <- (map["description"], ListTransform<DescriptionModel>())
        slug <- map["slug"]
        title <- (map["title"], ListTransform<DescriptionModel>())
        
        owner <- map["owner"]
        
        trigger <- map["trigger"]
        logic <- (map["logic"], JSONFormatterTransform())
        
        collection_id <- map["collection_id"]
        radius <- map["radius"]
        media <- (map["media"], ListTransform<MediaModel>())
        tags <- map["tags"]
        polygon <- (map["polygon"], JSONFormatterTransform())
        loc <- (map["loc"], JSONFormatterTransform())
        shape <- map["shape"]
        hide_zone <- map["hide_zone"]
        hide_player <- map["hide_player"]
        layer <- map["layer"]
        updated_at <- (map["updated_at"], CustomDateFormatterTransform())
        creation_date <- (map["creation_date"], CustomDateFormatterTransform())
        metadata <- (map["metadata"], ListTransform<MetadataModel>())
        
        lat <- (map["loc"], LatFormatterTransform())
        lng <- (map["loc"], LongFormatterTransform())
        
        prox_uuid <- map["prox_uuid"]
        prox_trig_dist <- map["prox_trig_dist"]
        prox_major_id <- map["prox_major_id"]
        prox_minor_id <- map["prox_minor_id"]
        
        size_bytes <- map["size_bytes"]
        
        elements <- (map["elements"], ListTransform<ElementModel>())
        //Check old value not from JSON
//        let oldObject = EchoesAPI.shared.getEcho(_id)
//        if oldObject != nil {
//            will_delete = false
//            isDownloaded = oldObject!.isDownloaded
//        }
    }
    
    public func getCirclePath() -> [CLLocationCoordinate2D] {
        var circlePath: [CLLocationCoordinate2D] = []
        let loc = self.loc.convertStringToJSON()
        let coords = loc!["coordinates"].arrayValue
        let centre = CLLocationCoordinate2D(latitude: coords[1].doubleValue, longitude: coords[0].doubleValue)
        let steps: Int = 100
        let circleStep = (2 * Double.pi) / Double(steps)
        for i in 0...steps {
            let bearing = Double(i) * circleStep
            circlePath.append(Helper.calculateCoordinate(from: centre, onBearing: bearing, atDistance: self.radius))
        }
        return circlePath
    }
    
    public func getPolygonPath() -> [CLLocationCoordinate2D] {
        var polygonPath: [CLLocationCoordinate2D] = []
        var points: [JSON] = []
        if let dataFromString = self.polygon.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            do {
                let json = try JSON(data: dataFromString)
                if json["coordinates"].arrayValue.count > 0 && json["coordinates"].arrayValue[0].arrayValue.count > 0 {
                    points = json["coordinates"].arrayValue[0].arrayValue
                }
            } catch {
                print("Error decoding polygon path data \(error)")
            }
        }
        
        for locString in points {
            var location:CLLocationCoordinate2D = CLLocationCoordinate2D()
            let latitude:Double = locString.arrayValue.count == 2 ? locString.arrayValue[1].doubleValue : 0
            let longitude:Double = locString.arrayValue.count == 2 ? locString.arrayValue[0].doubleValue : 0
            
            location = CLLocationCoordinate2DMake(latitude, longitude)
            polygonPath.append(location)
        }
        
        return polygonPath
    }
    
    public func getPolygonCoordsForCircleOrPolygon() -> [CLLocationCoordinate2D] {
        if self.shape.lowercased() == "circle" {
            return getCirclePath()
        } else {
            return getPolygonPath()
        }
    }
    
    public func getLogic() -> JSON {
        if let dataFromString = self.logic.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try SwiftyJSON.JSON(data: dataFromString)
                return json
            } catch {
                return SwiftyJSON.JSON()
            }
        }
        return SwiftyJSON.JSON()
    }
    
}
