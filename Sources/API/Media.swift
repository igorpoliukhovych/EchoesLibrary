//
//  Media.swift
//  Echoes
//
//  Created by Josh Kopecek on 17/07/2017.
//  Copyright © 2017 Echoes. All rights reserved.
//

import RealmSwift
import ObjectMapper
import ObjectMapper_Realm
import SwiftyJSON

open class MediaModel: Object, Mappable {
    @objc dynamic var rel:String?
    @objc dynamic var href:String?
    @objc dynamic var type:String?
    
    required public convenience init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        rel <- map["rel"]
        href <- map["href"]
        type <- map ["type"]
    }
}
