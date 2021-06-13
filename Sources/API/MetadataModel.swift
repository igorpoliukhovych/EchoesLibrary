//
//  DescriptionModel.swift
//  ECHOES
//
//  Created by Josh Kopecek on 11/04/2019.
//  Copyright © 2019 Echoes. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

open class MetadataModel: Object, Mappable {
    @objc public dynamic var _id = String.randomString(length: 12)
    @objc public dynamic var rel:String = ""
    @objc public dynamic var lang:String = "en"
    @objc public dynamic var text:String = ""
    
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
        rel <- map["rel"]
        lang <- map["lang"]
        text <- map["text"]
    }
}
