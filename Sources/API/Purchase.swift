//
//  Purchase.swift
//  Alamofire
//
//  Created by Juan Nuvreni on 22/08/18.
//

import Foundation
import RealmSwift
import ObjectMapper
import ObjectMapper_Realm
import SwiftyJSON
import Realm

public typealias ProductIdentifier = String

open class PurchaseModel: Object, Mappable {

    @objc public dynamic var sku = ""
    @objc public dynamic var type = "apple"
    @objc public dynamic var _id = ""
    @objc public dynamic var datePurchased = NSDate()
    
    var productId : ProductIdentifier {
        return sku
    }
    
    var asParams : [String : String] {
        return ["sku" : sku,
                "type": type]
    }
    
    convenience init(sku : String) {
        self.init()
        self.sku = sku
    }
    
    public required convenience init?(map: Map) {
        self.init()
    }
    
    required public init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required public init() {
        super.init()
    }
    
    required public init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    override public static func primaryKey() -> String? {
        return "sku"
    }
    
    override public static func indexedProperties() -> [String] {
        return ["sku"]
    }
    
    public func mapping(map: Map) {
        sku <- map["sku"]
        type <- map["type"]
        _id <- map["_id"]
        datePurchased <- (map["date_purchased"], CustomDateFormatterTransform(dateFormatterFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"))
    }
}
