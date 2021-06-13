//
//  LocationModel.swift
//  ECHOES
//
//  Created by Orest Mykha on 18.06.2020.
//  Copyright © 2020 Echoes. All rights reserved.
//

import ObjectMapper

final class LocationModel: Mappable {
    
    var text: String!
    var placeName: String!
    var geometry: Geometry!
    
    convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        text <- map["text"]
        placeName <- map["place_name"]
        geometry <- map["geometry"]
    }
    
}

final class Geometry: Mappable {
    
    var type: String!
    var coordinates: Array<Double>!
    
    convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        type <- map["type"]
        coordinates <- map["coordinates"]
    }
    
}
