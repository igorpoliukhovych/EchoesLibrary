//
//  StringExtensions.swift
//  Echoes
//
//  Created by Dmytro Hrebeniuk on 2/26/19.
//  Copyright © 2019 Echoes. All rights reserved.
//

import Foundation
import SwiftyJSON

extension String {
    
    var htmlString: NSAttributedString? {
        let styledHtml = "<div style=\"font-family: -apple-system, BlinkMacSystemFont, sans-serif;font-size: 16px;color: #757575\">\(self)</div>"
        
        let htmlData = styledHtml.data(using: String.Encoding.unicode)
        
        return htmlData.flatMap { data -> NSAttributedString? in
            do {
                return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            }
            catch {
                print("Couldn't parse \(self): \(error.localizedDescription)")
            }
            return nil
        }
    }
    
    func convertStringToJSON() -> JSON? {
        let data = self.data(using: String.Encoding.utf8)!
        do {
            let json = try JSON(data: data)
            
            return json
        } catch {
            print("Error making JSON \(error)")
            return nil
        }
    }
    
    func isOggFiles() -> Bool {
        return components(separatedBy: ".").last == "ogg"
    }
    
    var isValidEmail: Bool {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: self)
    }
    
    public func isImageType() -> Bool {
        let imageFormats = ["jpg", "png", "gif", "jpeg"]
        
        guard URL(string: self) != nil else { return false }
        
        let pathExtension = (self as NSString).pathExtension
        return imageFormats.contains(pathExtension)
    }
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        return formatter
    }()
    
    /**
     Remove all string at start and end of string
     
     :returns: String remove all start and end space
     */
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /**
     Remove all space
     
     :returns: String without space
     */
    func trimAll()->String{
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
    }
    
    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        return self.filter { okayChars.contains($0) }
    }
    
    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    //: ### Base64 decoding a string
    func base64Decoded() -> Data? {
        // prepare the jwt for base64 decoding
        let rem = self.count % 4
        
        var ending = ""
        if rem > 0 {
            let amount = 4 - rem
            ending = String(repeating: "=", count: amount)
        }
        
        let base64 = self.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/") + ending
        
        return Data(base64Encoded: base64)
    }
    
    static func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
}
