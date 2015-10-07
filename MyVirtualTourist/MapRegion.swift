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

@objc(MapRegion)

class MapRegion: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var latitudeDelta: Double
    @NSManaged var longitudeDelta: Double
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: Double, longitude: Double, latitudeDelta: Double, longitudeDelta: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("MapRegion", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

