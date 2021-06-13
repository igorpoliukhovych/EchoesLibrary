//
//  Collection.swift
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

public enum DownloadStatus: Int {
    case normal = 0
    case downloading
    case downloaded
    case error
}

public class CollectionModel: Object, Mappable {
    @objc public dynamic var _id = ""
    
    public var title = List<DescriptionModel>()
    public var desc = List<DescriptionModel>()
    @objc public dynamic var slug = ""
    
    @objc public dynamic var loc = ""
    @objc public dynamic var pub_status = ""
    
    @objc public dynamic var sell = false
    @objc public dynamic var price: Float = 0.0
    @objc public dynamic var isAlreadyPurchased = false
    
    public var channels = List<String>()
    public var tags = List<String>()
    public var categories = List<String>()
    public var views = List<String>()
    
    public var media = List<MediaModel>()
    public var echoes = List<EchoModel>()
    @objc public dynamic var creator: UserModel? = nil
    public var place = List<PlaceModel>()
    public var onboarding = List<OnboardingModel>()
    
    public var trajectories = List<TrajectoryModel>()
    
    @objc public dynamic var updated_at = NSDate()
    @objc public dynamic var creation_date = NSDate()
    @objc public dynamic var default_lang = ""
    
    @objc public dynamic var cstatus = 0
    @objc public dynamic var localIntroPath = ""
    @objc public dynamic var lat: Float = 0.0
    @objc public dynamic var lng: Float = 0.0
    
    @objc public dynamic var populated = false // the echoes have been downloaded
    @objc public dynamic var updatable = false // it's ready to update
    @objc public dynamic var size_bytes = 0
    
    @objc public dynamic var appleSku: String = ""
    
    public var profiles = List<ProfileModel>()
    
    public var getPrice: String? {
        get {
            return String.numberFormatter.string(from: NSDecimalNumber(floatLiteral: Double(price)))
        }
    }
    
    private var _totalSizeBytes: Int?
    public var totalSizeBytes: Int {
        get {
            if _totalSizeBytes != nil {
                return _totalSizeBytes!
            }
            let sizeBytes = echoes.reduce(0) { accEcho, echo in
                accEcho + echo.size_bytes + echo.elements.reduce(0) { $0 + $1.size_bytes }
            } + self.size_bytes
            _totalSizeBytes = sizeBytes
            return sizeBytes
        }
    }
    public var totalSizeBytesFormatted: String {
        get {
            return ByteCountFormatter.string(fromByteCount: Int64(totalSizeBytes), countStyle: .file)
        }
    }
    
    public var forSale: Bool {
        get {
            var forSale = self.sell && self.appleSku != ""
            
            #if DEBUG
            // test for if we have entered a sku
            forSale = self.appleSku != ""
            #endif
            return forSale
        }
    }
    
    public var titleText: String {
        get {
            return Helper.i18nise(self.title)
        }
    }
    public var descriptionText: String {
        get {
            return Helper.i18nise(self.desc)
        }
    }
    public var coverHref: String {
        get {
            return Helper.getMediaProperty(media: self.media)
        }
    }
    
    public var introHref: String {
        get {
            return Helper.getMediaProperty(media: self.media, for: "intro")
        }
    }
    
    public var placeShortNameText: String {
        get {
            if let i18nisedPlace = self.place.first(where: { $0.lang?.lowercased() == Locale.current.languageCode?.lowercased() }) {
                return i18nisedPlace.short_name ?? ""
            }
            return ""
        }
    }
    
    private func isLoggedUserSameAs(modelCreator : Map) -> Bool {
//        guard let userId = EchoesAPI.shared.getCurrentUser()?._id else { return false }
//        var creator: UserModel?
//        creator <- modelCreator["creator"]
//        if let unwrappedCreator = creator {
//            return unwrappedCreator._id == userId
//        }
        return false
    }
    
    public var downloadStatus: DownloadStatus {
        get {
            return DownloadStatus(rawValue: self.cstatus)!
        }
        set {
            self.cstatus = newValue.rawValue
        }
    }
    
    public var centreCoords: CLLocationCoordinate2D? {
        get {
            let data = self.loc.data(using: String.Encoding.utf8)!
            do {
                let json = try JSON(data: data)
                let coords = json["coordinates"].arrayValue
                if coords.count == 2 {
                    let loc = CLLocationCoordinate2D(latitude: coords[1].doubleValue, longitude: coords[0].doubleValue)
                    return loc
                }
                return nil
            } catch {
                print("Error decoding centreCoords data \(error)")
                return nil
            }
        }
    }
    
    public func distance(fromPoint:CLLocationCoordinate2D) -> CLLocationDistance? {
        let fromLocation: CLLocation = CLLocation(latitude: fromPoint.latitude, longitude: fromPoint.longitude)
        if let toPoint = self.centreCoords {
            let toLocation: CLLocation = CLLocation(latitude: toPoint.latitude, longitude: toPoint.longitude)
            return fromLocation.distance(from: toLocation)
        }
        return nil
    }
    
    override public static func primaryKey() -> String? {
        return "_id"
    }
    
    override public static func indexedProperties() -> [String] {
        return ["_id"]
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["titleText", "descriptionText"]
    }
    
    required convenience public init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        _id <- map["_id"]

        title <- (map["title"], ListTransform<DescriptionModel>())
        desc <- (map["description"], ListTransform<DescriptionModel>())
        
        slug <- map["slug"]
        
        loc <- (map["loc"], JSONFormatterTransform())
        pub_status <- map["pub_status"]
        
        sell <- map["sell"]
        if let channels = map.JSON["channels"] as? Array<String> {
            for channel in channels {
                self.channels.append(channel)
            }
        }
        if let tags = map.JSON["tags"] as? Array<String> {
            for tag in tags {
                self.tags.append(tag)
            }
        }
        if let categories = map.JSON["categories"] as? Array<String> {
            for category in categories {
                self.categories.append(category)
            }
        }
        
        media <- (map["media"], ListTransform<MediaModel>())
        echoes <- (map["echoes"], ListTransform<EchoModel>())
        place <- (map["place"], ListTransform<PlaceModel>())
        onboarding <- (map["onboarding"], ListTransform<OnboardingModel>())
        if let views = map.JSON["views"] as? Array<String> {
            for view in views {
                self.views.append(view)
            }
        }
    
        if !self.isLoggedUserSameAs(modelCreator:  map["creator"]) {
            self.creator <- map["creator"]
        }
       
        trajectories <- (map["trajectories"], ListTransform<TrajectoryModel>())
        
        updated_at <- (map["updated_at"], CustomDateFormatterTransform())
        creation_date <- (map["creation_date"], CustomDateFormatterTransform())
        default_lang <- map["default_lang"]
        
        lat <- (map["loc"], LatFormatterTransform())
        lng <- (map["loc"], LongFormatterTransform())
        
        appleSku <- map["iap.apple"]
        
        profiles <- (map["profiles"], ListTransform<ProfileModel>())
        
        size_bytes <- map["size_bytes"]
    }
    
    public func getUUIDs() -> [String] {
        var uuids: [String] = []
        self.echoes.forEach { echo in
            if !echo.prox_uuid.isEmpty {
                uuids.append(echo.prox_uuid)
            }
        }
        let uniqueUUIDs = Array(Set(uuids))
        return uniqueUUIDs
    }
    
}
