//
//  Pin.swift
//  MyVirtualTourist
//
//  Created by Dx on 12/10/15.
//  Copyright © 2015 Palmera. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import CoreLocation

class Pin: NSManagedObject {
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photos: [Photo]
    
    @NSManaged var flickrPage: NSNumber
    
    struct Keys {
        static let latitude: String = "latitude"
        static let longitude: String = "longitude"
        static let photos = "photos"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.latitude] as! Double
        longitude = dictionary[Keys.longitude] as! Double
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            let coordinate = CLLocationCoordinate2D(latitude: latitude.doubleValue, longitude: longitude.doubleValue )
            return coordinate
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    var annotation: MKPointAnnotation {
        get {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            return annotation
        }
    }
}