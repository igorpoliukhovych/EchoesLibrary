//
//  Onboarding.swift
//  TheRoyalParks
//
//  Created by Josh Kopecek on 10/04/2019.
//  Copyright © 2019 Echoes. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import SwiftyJSON

open class OnboardingModel: Object, Mappable {
    @objc public dynamic var _id = String.randomString(length: 12)
    var title = List<DescriptionModel>()
    var desc = List<DescriptionModel>()
    var media = List<MediaModel>()
    
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
        media <- (map ["media"], ListTransform<MediaModel>())
    }
    
    var titleText:String {
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
            return Helper.getMediaProperty(media: self.media)
        }
    }
}
