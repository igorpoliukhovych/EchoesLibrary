//
//  LocationModel.swift
//  ECHOES
//
//  Created by Orest Mykha on 18.06.2020.
//  Copyright © 2020 Echoes. All rights reserved.
//

import Foundation
import ObjectMapper

open class LocationModel: Mappable {
    
    public var text: String!
    public var placeName: String!
    public var geometry: Geometry!
    
    required public convenience init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        text <- map["text"]
        placeName <- map["place_name"]
        geometry <- map["geometry"]
    }
    
}

open class Geometry: Mappable {
    
    public var type: String!
    public var coordinates: Array<Double>!
    
    required public convenience init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        type <- map["type"]
        coordinates <- map["coordinates"]
    }
    
}
