//
//  Media.swift
//  Echoes
//
//  Created by Josh Kopecek on 17/07/2017.
//  Copyright © 2017 Echoes. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import SwiftyJSON

open class PlaceModel: Object, Mappable {
    @objc public dynamic var _id = String.randomString(length: 12)
    @objc public dynamic var lang: String?
    @objc public dynamic var short_name: String?
    @objc public dynamic var long_name: String?
    
    required public convenience init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        _id <- (map["_id"], IdDefaultTransform())
        lang <- map["lang"]
        short_name <- map["short_name"]
        long_name <- map ["long_name"]
    }
}
