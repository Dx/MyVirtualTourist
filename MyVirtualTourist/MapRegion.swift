//
//  MapRegion.swift
//  MyVirtualTourist
//
//  Created by Dx on 07/10/15.
//  Copyright © 2015 Palmera. All rights reserved.
//
//  Represents the region showed in the map

import Foundation
import CoreData
import MapKit
import CoreLocation

class MapRegion: NSManagedObject {
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var latitudeDelta: NSNumber
    @NSManaged var longitudeDelta: NSNumber
    
    struct Keys {
        static let latitude: String = "latitude"
        static let longitude: String = "longitude"
        static let latitudeDelta: String = "latitudeDelta"
        static let longitudeDelta: String = "longitudeDelta"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("MapRegion", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.latitude] as! Double
        longitude = dictionary[Keys.longitude] as! Double
        latitudeDelta = dictionary[Keys.latitudeDelta] as! Double
        longitudeDelta = dictionary[Keys.longitudeDelta] as! Double
    }
    
    var region: MKCoordinateRegion {
        get {
            let region = MKCoordinateRegion(center: coordinate, span: span)
            return region
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            let coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)
            return coordinate
        }
    }
    
    var span: MKCoordinateSpan {
        get {
            let span = MKCoordinateSpanMake(latitudeDelta.doubleValue, longitudeDelta.doubleValue)
            return span
        }
    }
}

