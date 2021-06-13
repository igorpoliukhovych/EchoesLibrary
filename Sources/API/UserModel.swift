//
//  User.swift
//  Echoes
//
//  Created by Josh Kopecek
//  Copyright (c) 2017 Echoes. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import SwiftyJSON

open class UserModel: Object, Mappable {
    
    @objc public dynamic var _id = ""
    @objc public dynamic var email = ""
    @objc public dynamic var name = ""
    @objc public dynamic var slug = ""
    @objc public dynamic var desc = ""
    public var media = List<MediaModel>()
    @objc public dynamic var reg_date = NSDate()
    @objc public dynamic var last_login_date = NSDate()
    public var purchases = List<PurchaseModel>()
    @objc public dynamic var loggedin = false
    @objc public dynamic var seenOnboarding = false
    @objc public dynamic var firebase_token = ""
    
    public var coverHref: String {
        get {
            return Helper.getMediaProperty(media: self.media)
        }
    }
    
    public var purchasesParameters: [String: Any] {
        var params: [String: Any] = [:]
        var objArray: [Any] = []
        purchases.forEach { objArray.append($0.asParams) }
        params["purchases"] = objArray
        
        return params
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
        email <- map["email"]
        name <- map["name"]
        slug <- map["slug"]
        desc <- (map["description"], JSONFormatterTransform())
        media <- (map["media"], ListTransform<MediaModel>())
        reg_date <- (map["reg_date"], CustomDateFormatterTransform())
        last_login_date <- (map["last_login_date"], CustomDateFormatterTransform())
        purchases <- (map["purchases"], ListTransform<PurchaseModel>())
        firebase_token <- map["firebase_token"]
    }
    
}
