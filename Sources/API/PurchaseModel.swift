//
//  Purchase.swift
//  Alamofire
//
//  Created by Juan Nuvreni on 22/08/18.
//

import Foundation
import RealmSwift
import ObjectMapper
import SwiftyJSON
import Realm

public typealias ProductIdentifier = String

open class PurchaseModel: Object, Mappable {

    @objc public dynamic var sku = ""
    @objc public dynamic var type = "apple"
    @objc public dynamic var _id = ""
    @objc public dynamic var datePurchased = NSDate()
    
    var productId: ProductIdentifier {
        return sku
    }
    
    var asParams: [String: String] {
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
    
    required public override init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        fatalError("init(realm:schema:) has not been implemented")
    }
    
    public required init(value: Any, schema: RLMSchema) {
        fatalError("init(value:schema:) has not been implemented")
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
        datePurchased <- (map["date_purchased"], CustomDateFormatterTransform())
    }
}
