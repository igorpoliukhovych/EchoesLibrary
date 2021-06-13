//
//  Media.swift
//  Echoes
//
//  Created by Josh Kopecek on 17/07/2017.
//  Copyright © 2017 Echoes. All rights reserved.
//

import RealmSwift
import ObjectMapper
import SwiftyJSON

open class MediaModel: Object, Mappable {
    
    @objc dynamic var id: String?
    @objc dynamic var rel: String?
    @objc dynamic var href: String?
    @objc dynamic var type: String?
    
    @objc public dynamic var imageData = Data()
    
    required public convenience init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        id <- map["id"]
        rel <- map["rel"]
        href <- map["href"]
        type <- map ["type"]
    }
    
}
