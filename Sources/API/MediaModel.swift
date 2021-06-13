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

open class MediaModel: Object, Mappable {
    
    @objc public dynamic var id: String?
    @objc public dynamic var rel: String?
    @objc public dynamic var href: String?
    @objc public dynamic var type: String?
    
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
