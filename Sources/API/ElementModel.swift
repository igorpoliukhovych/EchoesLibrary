//
//  ElementModel.swift
//  Duckworth Awakenings
//
//  Created by Josh Kopecek on 28/11/16.
//  Copyright © 2016 Echoes XYZ. All rights reserved.
//

import CoreLocation
import Foundation
import RealmSwift
import ObjectMapper
import SwiftyJSON

public enum ModelType : String {
    case text = "text"
    case image = "image"
    case sound = "sound"
    case none = ""
}

public enum ElementDownloadStatus: Int {
    case stream = 0
    case downloading
    case downloaded
}

open class ElementModel: Object, Mappable {
    @objc public dynamic var _id: String = ""
    @objc public dynamic var echo_id: String = ""
    @objc public dynamic var owner: String = ""
    @objc public dynamic var type: String = ""
    
    @objc public dynamic var play_loop: Bool = false
    @objc public dynamic var play_once: Bool = false
    @objc public dynamic var play_complete: Bool = false
    @objc public dynamic var spatialization: Bool = false
    @objc public dynamic var threed: Bool = false
    @objc public dynamic var resume: Bool = false
    
    @objc public dynamic var threed_min_dist: Float = 0.0
    @objc public dynamic var threed_max_dist: Float = 20.0
    @objc public dynamic var threed_rolloff: String = "inverse"
    @objc public dynamic var relative_elevation: Float = 0.0
    
    @objc public dynamic var fade_in_ms: Int = 0
    @objc public dynamic var fade_out_ms: Int = 500
    
    @objc public dynamic var loc: String = ""
    
    @objc public dynamic var tempo: Float = 120
    @objc public dynamic var sync_beats: Int = 4
    @objc public dynamic var sync_group: Int = -1
    
    @objc public dynamic var pub_status: String = ""
    
    @objc public dynamic var media_href = ""
    @objc public dynamic var media_rel = ""
    
    @objc public dynamic var updated_at: NSDate = NSDate()
    @objc public dynamic var creation_date: NSDate = NSDate()
    
    @objc public dynamic var slug: String = ""
    @objc public dynamic var title: String = ""
    @objc public dynamic var desc: String = ""
    
    @objc public dynamic var size_bytes = 0
    
    @objc public dynamic var localPath: String = ""
    @objc public dynamic var will_delete: Bool = false
    
    @objc public dynamic var downloadStatusEnum = 0
    @objc public dynamic var downloadProgress: Double = 0.0
    
    public var modelDataType: ModelType {
        return ModelType(rawValue: type) ?? ModelType.none
    }

//    var player: EchoesPlayerBase?
    
    public var soundPath: URL? {
        get {
            if self.localPath != "" {
                let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                if self.localPath.contains("Application") {
                    return URL(string: self.localPath)
                } else {
                    let finalPath = directoryURL.appendingPathComponent(self.localPath)
                    return finalPath
                }
            } else if self.media_href != "" {
                return URL(string: self.media_href)!
            } else {
                return nil
            }
        }
    }
    
    public var is3d: Bool {
        get {
            return type == "ambisonic" || threed
        }
    }
    
    public var needsFmod: Bool {
        get {
            return type == "ambisonic" || threed || sync_group > -1 || soundPath?.pathExtension ?? "" == "ogg"
        }
    }
    
    public var downloadStatus: ElementDownloadStatus {
        get {
            return ElementDownloadStatus(rawValue: self.downloadStatusEnum)!
        }
        set {
            self.downloadStatusEnum = newValue.rawValue
        }
    }
    
    public var coords: CLLocationCoordinate2D? {
        get {
            let location = loc.convertStringToJSON()
            if location == nil {
                return nil
            }
            if let coords = location?["coordinates"].arrayValue, !coords.isEmpty {
                return CLLocationCoordinate2D(latitude: coords[1].doubleValue, longitude: coords[0].doubleValue)
            } else {
                return nil
            }
        }
    }
    
    public var isNotSound: Bool {
        get {
            if self.type != "sound" && self.type != "ambisonic" {
                return true
            }
            
            return false
        }
    }
    
    override public static func primaryKey() -> String? {
        return "_id"
    }
    
    override public static func indexedProperties() -> [String] {
        return ["_id"]
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["player"]
    }
    
    required public convenience init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        _id <- map["_id"]
        echo_id <- map["echo_id"]
        owner <- map["owner"]
        type <- map["type"]
        play_loop <- map["play_loop"]
        play_once <- map["play_once"]
        play_complete <- map["play_complete"]
        spatialization <- map["spatialization"]
        threed <- map["threed"]
        resume <- map["resume"]
        fade_in_ms <- map["fade_in_ms"]
        fade_out_ms <- map["fade_out_ms"]
        threed_min_dist <- map["threed_min_dist"]
        threed_max_dist <- map["threed_max_dist"]
        threed_rolloff <- map["threed_rolloff"]
        relative_elevation <- map["relative_elevation"]
        
        loc <- (map["loc"], JSONFormatterTransform())
        
        tempo <- map["tempo"]
        sync_beats <- map["sync_beats"]
        sync_group <- map["sync_group"]
        
        pub_status <- map["pub_status"]
        media_href <- map["media.href"]
        media_rel <- map["media.rel"]
        updated_at <- (map["updated_at"], CustomDateFormatterTransform())
        creation_date <- (map["creation_date"], CustomDateFormatterTransform())
        slug <- map["slug"]
        title <- (map["title"], JSONFormatterTransform())
        desc <- (map["description"], JSONFormatterTransform())
        
        size_bytes <- map["size_bytes"]
    }
    
}
