//
//  Echo.swift
//  Echoes
//
//  Created by Josh Kopecek on 29/08/2017.
//  Copyright © 2017 Echoes. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import SwiftyJSON
import UIKit
import Turf

/// The current status of an echo - whether it's been triggered or not
@objc public enum EchoStatus: Int {
    /// The echo has not been triggered
    case inactive
    /// The echo has been triggered
    case active
}

/// The current status of whether we're inside or outside an echo
@objc public enum EchoLocationStatus: Int {
    //// We're outside the echo
    case outside
    /// We're inside the echo
    case inside
}

public enum EchoLoadingState {
    case unloaded
    case loading
    case loaded
    case error
}

struct SoundsModel {
    var mediaHref: String?
    var element: ElementModel
    var coords: CLLocationCoordinate2D?
}

open class Echo : NSObject {
    
    var delegate: EchoDelegate?
    var model:EchoModel?
    
    var polygon:Polygon?
    var polygonPath:[CLLocationCoordinate2D] = []
    var polygonCentre:CLLocationCoordinate2D!
    
    var centreCoords:CLLocationCoordinate2D?
    var centreCoordsLocation:CLLocation?
    
    var collectionCentreCoords:CLLocationCoordinate2D?
    var relativeLocationInMetres:(Double, Double) = (0, 0)
    
    var statusHasChanged = false
    var selected:Bool = false
    @objc public dynamic var estatus:EchoStatus = .inactive {
        didSet {
            if oldValue != estatus {
                NotificationCenter.default.post(name: NSNotification.Name.DetriggerEcho, object: nil)
            }
        }
    }
    var elocstatus:EchoLocationStatus = .outside
    
    var players: [EchoesPlayerBase] = []
    
    var titleText:String = ""
    var descriptionText:String = ""
    var coverHref:String = ""
    var spatialization:Bool = false
    
    var loadingState:EchoLoadingState = .unloaded
    var offline:Bool = false
    
    var triggeredCount:Int = 0
    var playedCount:Int {
        get {
            guard self.players.count > 0 else { return 0 }
            return self.players.reduce(0) { (prev, player) in
                return prev + player.playedCount
            }
        }
    }
    
    var kFilter = KalmanFilter(stateEstimatePrior: 100.0, errorCovariancePrior: 29)
    
    init(withEcho echo: EchoModel, offline: Bool = false, collectionCentreCoords: CLLocationCoordinate2D? = nil) {
        super.init()
        self.model = echo
        self.offline = offline
        // initialise centre coords:
        let loc = echo.loc.convertStringToJSON()
        let coords = loc!["coordinates"].arrayValue
        self.centreCoords = CLLocationCoordinate2D(latitude: coords[1].doubleValue, longitude: coords[0].doubleValue)
        self.centreCoordsLocation = CLLocation(latitude: (self.centreCoords?.latitude)!, longitude: (self.centreCoords?.longitude)!)
        self.collectionCentreCoords = collectionCentreCoords
        
        // initialise title
        self.titleText = self.model!.titleText
        // initialise description
        self.descriptionText = self.model!.descriptionText
        // initialise cover href
        self.coverHref = self.model!.coverHref
        
        if echo.shape.lowercased() == "polygon" {
            // initialise polygon
            self.setupPolygon()
            self.setPolygonCentre()
        }
        
        // set spatialization if any elements have it
        self.spatialization = self.model!.elements.reduce(false, {acc, element in
            return acc || element.spatialization
        })
        
        // allocate the right number of spots in the players array
        self.players.reserveCapacity(self.model?.elements.count ?? 1)
    }
    
    func getSounds() -> [SoundsModel]? {
        guard let elements = model?.elements else {
            return nil
        }
        return elements.filter { $0.media_href != "" }.map { el in
            var coords: CLLocationCoordinate2D? = el.coords
            if coords == nil {
                coords = self.centreCoords
            }
            return SoundsModel(
                mediaHref: el.media_href,
                element: el,
                coords: coords)
        }
    }
    
    public func loadPlayers(andPlay: Bool = false, withGain gain: Float? = nil, completion: (() -> ())? = nil) {
        if self.loadingState == .unloaded {
            self.loadingState = .loading
            guard let allSounds = getSounds() else {
                return
            }
            let soundLoadingGroup = DispatchGroup()
            for (i, soundModel) in allSounds.enumerated() {
                // enter the dispatch group
                soundLoadingGroup.enter()
                
                if EchoesEngine.shared.needsFmod {
                    // it's 3D, let's use the 3D player
                    if soundModel.element.soundPath != nil && soundModel.element.soundPath!.path != "" {
                        if let location = soundModel.element.coords,
                           let origin = collectionCentreCoords {
                            relativeLocationInMetres = location.toMetres(origin: origin)
                        }
                        
                        let player = EchoesPlayer3D(
                            withFile: soundModel.element.soundPath!,
                            withGain: gain ?? 1.0,
                            withElement: soundModel.element,
                            offline: true,
                            location: relativeLocationInMetres,
                            playWhenReady: andPlay
                        ) { isPlayerCreated in
                            if !isPlayerCreated && self.players.indices.contains(i) {
                                self.players[i].unload()
                                self.players.remove(at: i)
                            }
                        }
                        self.players.insert(player, at: i)
                        soundLoadingGroup.leave()
                    }
                } else if self.offline {
                    // it's offline, so we try to use the local files
                    if soundModel.element.soundPath != nil && soundModel.element.soundPath!.path != "" {
                        let player = EchoesPlayerOffline(withFile: soundModel.element.soundPath!, withGain: gain ?? 1.0, withElement: soundModel.element, playWhenReady: andPlay) { [weak self] isPlayerCreated in
                            guard let strongSelf = self else {
                                return
                            }
                            if !isPlayerCreated {
                                if strongSelf.players.indices.contains(i) {
                                    strongSelf.players[i].unload()
                                    strongSelf.players.remove(at: i)
                                }
                            }
                            // it's loaded, leave the group
                            soundLoadingGroup.leave()
                        }
                        self.players.insert(player, at: i)
                    } else {
                        // no soundpath, leave the group
                        soundLoadingGroup.leave()
                    }
                } else {
                    guard let mediaHref = soundModel.mediaHref else {
                        // no href, leave the group
                        soundLoadingGroup.leave()
                        return
                    }
                    let soundPath = URL(string: mediaHref)
                    let player = EchoesPlayerStream(withFile: soundPath!, withGain: gain ?? 1.0, withElement: soundModel.element, playWhenReady: andPlay)
                    self.players.insert(player, at: i)
                    soundLoadingGroup.leave()
                }
            }
            
            soundLoadingGroup.notify(queue: .main) {
                if allSounds.count == self.players.count {
                    self.loadingState = .loaded
                }
                completion?()
            }
        }
    }
    
    public func unloadPlayers() {
        for (_, player) in self.players.enumerated() {
            player.unload()
        }
        for (i, _) in self.players.enumerated() {
            self.players[i].unload()
        }
        self.loadingState = .unloaded
    }
    
    public func isPolygon() -> Bool {
        return self.model!.shape.lowercased() == "polygon"
    }
    
    /**
     Determine if a particular location is inside this Echo's shape
     
     - Parameter location: The location we want to check against
     */
    public func locationIsInside(location: CLLocationCoordinate2D) -> Bool {
        if (self.model?.shape.lowercased() == "polygon") {
            if self.polygon != nil {
                return self.polygon?.contains(location) ?? false
            }
            // get the polygon's coordinates
            var path = self.polygonPath
            // create a path to
            let bezier = UIBezierPath()
            let firstPoint = path[0]
            path.removeFirst(1)
            bezier.move(to: CGPoint(x: firstPoint.latitude, y: firstPoint.longitude))
            path.forEach { coordinate in
                bezier.addLine(to: CGPoint(x: coordinate.latitude, y: coordinate.longitude))
            }
            bezier.close()
            return bezier.contains(CGPoint(x: location.latitude, y: location.longitude))
        } else {
            if centreCoordsLocation == nil { return false }
            let currentLocationLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            guard let radius = self.model?.radius else { return false }
            return currentLocationLocation.distance(from: centreCoordsLocation!) <= radius
        }
    }
    
    public func setupPolygon() -> Void {
        self.polygonPath = self.model!.getPolygonPath()
        self.polygon = Polygon([self.polygonPath])
    }
    
    public func setPolygonCentre() -> Void {
        var listCoords = [CLLocationCoordinate2D]()
        var countLoc = 0
        var x = 0.0 as CGFloat
        var y = 0.0 as CGFloat
        var z = 0.0 as CGFloat
        
        for i in ( 0..<self.polygonPath.count ) {
            let location = self.polygonPath[i]
            listCoords.append(location)
            let lat:CGFloat = Helper.shared.degreeToRadian(location.latitude)
            let lon:CGFloat = Helper.shared.degreeToRadian(location.longitude)
            x = x + cos(lat) * cos(lon)
            y = y + cos(lat) * sin(lon);
            z = z + sin(lat);
            countLoc += 1
        }
        
        x = x/CGFloat(countLoc)
        y = y/CGFloat(countLoc)
        z = z/CGFloat(countLoc)
        
        let resultLon: CGFloat = atan2(y, x)
        let resultHyp: CGFloat = sqrt(x*x+y*y)
        let resultLat:CGFloat = atan2(z, resultHyp)
        let newLat = Helper.shared.radianToDegree(resultLat)
        let newLon = Helper.shared.radianToDegree(resultLon)
        self.polygonCentre = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
    }
    
    public func shouldSetZoneColours() -> Bool {
        if self.statusHasChanged {
            self.statusHasChanged = false
            switch self.estatus {
            case .active:
                return true
            case .inactive:
                return true
            }
        }
        return false
    }
    
    public func getZoneColours() -> ZoneColours {
        var colors:ZoneColours = ZoneColours()
        // set the zones to be transparent by default
        var fillColor:UIColor?
        var strokeColor:UIColor?
        if self.estatus == .active {
            // active zones
            fillColor = UIColor.zoneBlueAlpha
            strokeColor = UIColor.zoneBlueAlpha
        } else {
            // inactive zones
            fillColor = UIColor.zoneLightBlueAlpha
            strokeColor = UIColor.zoneBlueAlpha
        }
        if self.selected {
            // unselected zones should have darker fills
            fillColor = UIColor.zoneYellowAlpha
            strokeColor = UIColor.zoneYellowAlpha
        }
        if (self.model!.hide_zone) {
            // completely hide the zone
            fillColor = fillColor!.withAlphaComponent(0)
            strokeColor = fillColor!.withAlphaComponent(0)
        }
        colors.fillColor = fillColor
        colors.strokeColor = strokeColor
        
        return colors
    }
    
    public func trigger(currentLocation: CLLocationCoordinate2D, triggerType trigger: String, locationUpdateInterval: TimeInterval = 0) {
        if self.statusHasChanged {
            self.statusHasChanged = false
        }
        
        // Let's play!
        // only set the gain to 1 if we're inside
        // - this is relevant for sync group items where we want them to play at 0 volume
        var gain:Float = self.elocstatus == .inside ? 1.0 : 0.0
        if (trigger == "location" && self.model?.shape.lowercased() == "circle" && self.spatialization) {
            gain = self.getGainFrom(currentLocation: currentLocation)
        }
        if self.estatus != .active {
            self.statusHasChanged = true
            self.estatus = .active
            self.triggeredCount += 1
            if !self.isPlaying() {
                self.play(withGain: gain)
            }
            AnalyticsManager.track(event: .trigger_echo, properties: [
                EventPropertyKey.item_id.rawValue: self.model!._id,
                EventPropertyKey.item_name.rawValue: self.model!.titleText,
                EventPropertyKey.content_type.rawValue: "echo",
                EventPropertyKey.trigger_type.rawValue: trigger
            ])
        } else {
            self.setGain(withGain: gain, locationUpdateInterval: locationUpdateInterval)
        }
    }
    
    public func trigger() {
        if self.statusHasChanged {
            self.statusHasChanged = false
        }
        
        // Let's play!
        // only set the gain to 1 if we're inside
        // - this is relevant for sync group items where we want them to play at 0 volume
        let gain:Float = self.elocstatus == .inside ? 1.0 : 0.0
        
        if self.estatus != .active {
            self.statusHasChanged = true
            self.estatus = .active
            self.triggeredCount += 1
            if !self.isPlaying() {
                self.play(withGain: gain)
            }
            AnalyticsManager.track(event: .trigger_echo, properties: [
                EventPropertyKey.item_id.rawValue: self.model!._id,
                EventPropertyKey.item_name.rawValue: self.model!.titleText,
                EventPropertyKey.content_type.rawValue: "echo",
                EventPropertyKey.trigger_type.rawValue: "beacon"
            ])
        }
    }
    
    public func getGainFrom(currentLocation: CLLocationCoordinate2D) -> Float {
        var gain:Float = 1.0
        let centreCoordsLocation = CLLocation(latitude: (self.centreCoords?.latitude)!, longitude: (self.centreCoords?.longitude)!)
        let currentLocationLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let currentDistance = currentLocationLocation.distance(from: centreCoordsLocation)
        // we can potentially be outside a zone and it still play, so in this case we set gain to 0
        if currentDistance > (self.model?.radius ?? 0.0) {
            gain = 0.0
        } else {
            // make sure the gain is between 0 and 1
            gain = (0.0 ... 1.0).clamp(value: Float(1.0 - (currentDistance / (self.model?.radius)!)))
        }
        return gain
    }
    
    public func detrigger() {
        self.statusHasChanged = true
        if self.estatus == .active {
            self.estatus = .inactive
            self.pauseOrStop()
            AnalyticsManager.track(event: .detrigger_echo, properties: [
                EventPropertyKey.item_id.rawValue: self.model!._id,
                EventPropertyKey.item_name.rawValue: self.model!.titleText,
                EventPropertyKey.content_type.rawValue: "echo"
            ])
        }
    }
    
    public func play(withGain gain:Float, force: Bool = false) {
        if self.loadingState == .unloaded {
            // looks like we're trying to play a non-loaded file
            self.loadPlayers(andPlay: true, withGain: gain)
        } else {
            self.playWithGain(gain: gain)
        }
    }
    
    private func playWithGain(gain: Float, force: Bool = false) {
        for player in self.players {
            // still must check for a non-nil player - we could be missing a file
            if force || player.shouldPlay() {
                player.playState = .playing
                self.setGain(withGain: gain)
                player.play(nil)
                NotificationCenter.default.post(name: NSNotification.Name.EchoStartedPlaying, object: nil, userInfo: ["echo" : self])
            }
        }
        delegate?.didPlay(echo: self)
    }
    
    /**
     Pause or resume the players
     
     Called by detrigger only - should obey 'resume'
     */
    public func pauseOrStop(force:Bool = false) {
        for (_, element) in self.model!.elements.enumerated() {
            if element.resume {
                self.pause(force: force)
            } else {
                self.stop(force: force)
            }
        }
        delegate?.didPause(echo: self)
    }
    
    public func pause(force:Bool = false) {
        for player in self.players where player.shouldStop(force: force) {
            let fade = TimeInterval(Double(player.fadeOutMs) / 1000) // fade out in ms
            player.pause(withFade: fade, force: force)
            NotificationCenter.default.post(name: NSNotification.Name.EchoStoppedPlaying, object: nil, userInfo: ["echo" : self])
        }
        delegate?.didPause(echo: self)
    }
    
    public func stop(force:Bool = false) {
        for player in self.players where player.shouldStop(force: force) {
            let fade = TimeInterval(Double(player.fadeOutMs) / 1000) // fade out in ms
            player.stop(withFade: fade, force: force)
            NotificationCenter.default.post(name: NSNotification.Name.EchoStoppedPlaying, object: nil, userInfo: ["echo" : self])
        }
        delegate?.didStop(echo: self)
    }
    
    public func stopPlayers(withFade fade:TimeInterval = 0.5, force:Bool = false) {
        for player in self.players {
            player.stop(withFade: fade, force: force)
        }
        delegate?.didStop(echo: self)
    }
    
    public func startSeeking() {
        for player in self.players {
            player.startSeeking()
        }
    }
    
    public func stopSeeking(percentage: Double) {
        for player in self.players {
            player.stopSeeking(percentage: percentage)
        }
    }
    
    public func setGain(withGain gain:Float, locationUpdateInterval: TimeInterval = 0) {
        for player in self.players {
            player.setPlayerGain(gain, locationUpdateInterval)
        }
    }
    
    public func isPlaying() -> Bool {
        return (self.players.reduce(false) { prev, player in
            return player.isPlaying()
        })
    }
    
    public func getPlayingPlayers() -> [EchoesPlayerBase]? {
        return self.players.filter({ $0.isPlaying() })
    }
    
    public func getTotalTime() -> Double {
        return self.players.first?.duration ?? 1.0
    }
    
    public func getTotalTimePrintable() -> String {
        let totalTime  = getTotalTime()
        return totalTime.asPrintableTime
    }
    
    public func getIntersectionOfPolygon(withLine line: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        var pointIntersections:[CLLocationCoordinate2D] = []
        // get the total number of coordinates in the polygon
        let totalNumCoords = self.polygonPath.count
        // loop through all the coordinates bar one
        // the last one will be used as the second coordinate of the last line
        for i in 0 ..< totalNumCoords - 1 {
            // construct a line from the current polygon segment
            var polygonSegmentLine:[CLLocationCoordinate2D] = []
            polygonSegmentLine.append(self.polygonPath[i])
            polygonSegmentLine.append(self.polygonPath[i + 1])
            
            // work out if the distance between the two sets of coordinates sums to zero
            let distance = (polygonSegmentLine[1].latitude - polygonSegmentLine[0].latitude) * (line[1].longitude - line[0].longitude) - (polygonSegmentLine[1].longitude - polygonSegmentLine[0].longitude) * (line[1].latitude - line[0].latitude)
            if distance == 0 {
                print("error, parallel lines")
                return pointIntersections
            }
            
            let u = ((line[0].latitude - polygonSegmentLine[0].latitude) * (line[1].longitude - line[0].longitude) - (line[0].longitude - polygonSegmentLine[0].longitude) * (line[1].latitude - line[0].latitude)) / distance
            let v = ((line[0].latitude - polygonSegmentLine[0].latitude) * (polygonSegmentLine[1].longitude - polygonSegmentLine[0].longitude) - (line[0].longitude - polygonSegmentLine[0].longitude) * (polygonSegmentLine[1].latitude - polygonSegmentLine[0].latitude)) / distance
            
            if (u < 0.0 || u > 1.0) {
                print("error, intersection not inside line1")
                return pointIntersections
            }
            if (v < 0.0 || v > 1.0) {
                print("error, intersection not inside line2")
                return pointIntersections
            }
            pointIntersections.append(CLLocationCoordinate2D(latitude: polygonSegmentLine[0].latitude + u * (polygonSegmentLine[1].latitude - polygonSegmentLine[0].latitude), longitude: polygonSegmentLine[0].longitude + u * (polygonSegmentLine[1].longitude - polygonSegmentLine[0].longitude)))
        }
        return pointIntersections
    }
    
    var _description: String {
        return "EchoModel id: \(String(describing: model?._id))"
    }
    
    var is3D: Bool {
        get {
            let is3DObjects = model?.elements.map { $0.needsFmod }
            if is3DObjects?.contains(true) ?? false {
                return true
            }
            
            return false
        }
    }
    
}

open class EchoesMarker {
    var echo:Echo!
}

public struct ZoneColours {
    var fillColor:UIColor?
    var strokeColor:UIColor?
}

extension Echo: EchoesPlayerDelegate {
    func didFinishPlaying() {
        delegate?.didFinishPlaying(echo: self)
    }
}
