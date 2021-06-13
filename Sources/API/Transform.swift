//
//  Transform.swift
//  Strassbuch
//
//  Created by cuong bui on 9/8/16.
//  Copyright © 2016 Asterix. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON

public class CustomDateFormatterTransform: TransformType {
    public typealias Object = NSDate
    public typealias JSON = String
    
    let dateFormatter: DateFormatter
    
    public init(dateFormatterFormat: String) {
        let df = DateFormatter()
        df.dateFormat = dateFormatterFormat
        self.dateFormatter = df
    }
    
    convenience init() {
        self.init(dateFormatterFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    }
    
    public func transformFromJSON(_ value: Any?) -> NSDate? {
        if let dateString = value as? String {
            return dateFormatter.date(from: dateString) as NSDate?
        }
        return nil
    }
    
    public func transformToJSON(_ value: NSDate?) -> String? {
        if let date = value {
            return dateFormatter.string(from: date as Date)
        }
        return nil
    }
}

public class JSONFormatterTransform: TransformType {
    public typealias Object = String
    public typealias JSON = String
    
    
    public func transformFromJSON(_ value: Any?) -> String? {
        return SwiftyJSON.JSON(value!).rawString()
    }
    
    public func transformToJSON(_ value: String?) -> String? {
        return value
    }
}

public class LatFormatterTransform: TransformType {
    public typealias Object = Float
    public typealias JSON = String
    
    
    public func transformFromJSON(_ value: Any?) -> Float? {
        let loc = SwiftyJSON.JSON(value!)
        var lat:Float = 0.0
        if(loc["type"].stringValue == "Point"){
            let location = loc["coordinates"].arrayValue
            if(location.count == 2){
                lat = location[1].floatValue
            }
        }
        return lat
        
    }
    
    public func transformToJSON(_ value: Float?) -> String? {
        return String(describing: value)
    }
}

public class LongFormatterTransform: TransformType {
    public typealias Object = Float
    public typealias JSON = String
    
    
    public func transformFromJSON(_ value: Any?) -> Float? {
        let loc = SwiftyJSON.JSON(value!)
        var long:Float = 0.0
        if(loc["type"].stringValue == "Point"){
            let location = loc["coordinates"].arrayValue
            if(location.count == 2){
                long = location[0].floatValue
            }
        }
        return long
        
    }
    
    public func transformToJSON(_ value: Float?) -> String? {
        return String(describing: value)
    }
}

public class IdDefaultTransform: TransformType {
    public typealias Object = String
    public typealias JSON = String
    
    
    public func transformFromJSON(_ value: Any?) -> String? {
        var id = SwiftyJSON.JSON(value!).stringValue
        if(id == ""){
            id = String.randomString(length: 12)
        }
        return id
        
    }
    
    public func transformToJSON(_ value: String?) -> String? {
        return String(describing: value)
    }
}
