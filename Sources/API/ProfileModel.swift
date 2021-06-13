//
//  ProfileModel.swift
//  ECHOES
//
//  Created by Mac_2 on 10/30/19.
//  Copyright © 2019 Echoes. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import SwiftyJSON

open class ProfileModel: Object, Mappable {
    
    @objc public dynamic var active: String = ""
    @objc public dynamic var _id: String = ""
    @objc public dynamic var name: String = ""
    public var descriptionProfile = List<ProfileDescriptionModel>()
    @objc public dynamic var pub_status: String = ""
    @objc public dynamic var slug: String = ""
    @objc public dynamic var creation_date: NSDate = NSDate()
    @objc public dynamic var updated_at: NSDate = NSDate()
    @objc public dynamic var v: String = ""
    @objc public dynamic var totalCount: Int = 0
    @objc public dynamic var num_public_collections: Int = 0
    public var media = List<MediaModel>()
    
    public var profileHref: String {
        get {
            return Helper.getMediaProperty(media: self.media, for: "profile-photo")
        }
    }
    
    public var coverHref: String {
        get {
            return Helper.getMediaProperty(media: self.media)
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
        active <- map["active"]
        _id <- map["_id"]
        name <- map["name"]
        descriptionProfile <- (map["description"], ListTransform<ProfileDescriptionModel>())
        media <- (map["media"], ListTransform<MediaModel>())
        pub_status <- map["pub_status"]
        slug <- map["slug"]
        creation_date <- (map["creation_date"], CustomDateFormatterTransform())
        updated_at <- (map["updated_at"], CustomDateFormatterTransform())
        v <- map["v"]
        num_public_collections <- map["num_public_collections"]
    }
    
}

open class ProfileDescriptionModel: Object, Mappable {
    
    @objc public dynamic var lang: String = ""
    @objc public dynamic var _id: String = ""
    @objc public dynamic var text: String = ""
    
    required convenience public init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        lang <- map["lang"]
        _id <- map["_id"]
        text <- map["text"]
    }
    
}
