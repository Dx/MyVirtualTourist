//
//  ViewController.swift
//  MyVirtualTourist
//
//  Created by Dx on 06/10/15.
//  Copyright © 2015 Palmera. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate {

    @IBOutlet weak var touristMap: MKMapView!

    var mapRegion: MapRegion?
    
    var isInitialLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        touristMap.delegate = self

        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "createPin:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        touristMap.addGestureRecognizer(longPressRecogniser)
        
        setMapRegion()
        
        isInitialLoad = false
    }
    
    // MARK: - Shared Context
    
    lazy var sharedContext: NSManagedObjectContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    // MARK: MapRegion functions
    
    func setMapRegion() {
        
        // Get persisted MapRegion instance from Core data (if any exists) and save it to both the view controller's private mapRegion property, and the mapView's region.
        let regions = fetchMapRegions()
        if regions.count > 0 {
            // Use the persisted value for the region.
            
            // set the view controller's mapRegion property
            self.mapRegion = regions[0]
            
            // Set the mapView's region.
            self.touristMap.region = regions[0].region
        }
    }
    
    /* Save this view controller's mapRegion to the context after updating it to the mapView's current region. */
    func saveMapRegion() {
        
        if isInitialLoad { return }
        
        if self.mapRegion != nil {
            // Set the mapRegion property to the mapView's current region.
            self.mapRegion!.latitude = self.touristMap.region.center.latitude
            self.mapRegion!.longitude = self.touristMap.region.center.longitude
            self.mapRegion!.latitudeDelta = self.touristMap.region.span.latitudeDelta
            self.mapRegion!.longitudeDelta = self.touristMap.region.span.longitudeDelta
            
        } else {
            // Create a map region instance initialized to the mapView's current region.
            var dict = [String: AnyObject]()
            dict[MapRegion.Keys.latitude] = self.touristMap.region.center.latitude
            dict[MapRegion.Keys.longitude] = self.touristMap.region.center.longitude
            dict[MapRegion.Keys.latitudeDelta] = self.touristMap.region.span.latitudeDelta
            dict[MapRegion.Keys.longitudeDelta] = self.touristMap.region.span.longitudeDelta
            self.mapRegion = MapRegion(dictionary: dict, context: sharedContext)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        let regions = fetchMapRegions()
        print("Regions counter \(regions.count)")
    }
    
    func fetchMapRegions() -> [MapRegion] {
        var error: NSError?
        
        let fetchRequest = NSFetchRequest(entityName: "MapRegion")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: false)]
        
        let results: [AnyObject]?
        
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            results = nil
        }
        
        // Check for Errors
        if let error = error {
            print("Unresolved error \(error), \(error.userInfo)", terminator: "")
            abort()
        }
        
        return results as? [MapRegion] ?? [MapRegion]()
    }
    
    // MARK: - map functions
    
    func createPin(gestureRecognizer : UIGestureRecognizer){
        if gestureRecognizer.state != .Began { return }
        
        let touchPoint = gestureRecognizer.locationInView(self.touristMap)
        let touchMapCoordinate = touristMap.convertPoint(touchPoint, toCoordinateFromView: touristMap)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        touristMap.addAnnotation(annotation)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Changes: \(mapView.region.center.latitude, mapView.region.center.longitude, mapView.region.center.longitude)")
        saveMapRegion()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

