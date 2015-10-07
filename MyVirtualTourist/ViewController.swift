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

class ViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var touristMap: MKMapView!

    var mapRegion = MKCoordinateRegion()
    
    var regionFilePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        return url.URLByAppendingPathComponent("mapRegion").path!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "createPin:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        touristMap.addGestureRecognizer(longPressRecogniser)
        
        fetchMapRegion()
    }
    
    override func viewWillDisappear(animated: Bool) {
        saveMapRegion()
    }
    
    // MARK: - Shared Context
    
    lazy var sharedContext: NSManagedObjectContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func fetchRegion() {
        var error: NSError?
        var coordinateRegion: MKCoordinateRegion?
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "MapRegion")
        
        // Execute the Fetch Request
        let results: [AnyObject]?
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
            if let resultsValid = results {
                if let mapRegion: MapRegion = (resultsValid[0] as! MapRegion) {
                    let center = CLLocationCoordinate2D(latitude: mapRegion.latitude, longitude: mapRegion.longitude)
                    let span = MKCoordinateSpan(latitudeDelta: mapRegion.latitudeDelta, longitudeDelta: mapRegion.longitudeDelta)
                    coordinateRegion = MKCoordinateRegion(center: center, span: span)
                }
            }
            
        } catch let error1 as NSError {
            error = error1
            coordinateRegion = nil
        }
        
        // Check for Errors
        if let error = error {
            print("Error in fetchRegion(): \(error)")
        }
        
        if coordinateRegion != nil {
            touristMap.setRegion(coordinateRegion!, animated: true)
        }
    }
    
    // MARK: - functions
    
    func createPin(gestureRecognizer : UIGestureRecognizer){
        if gestureRecognizer.state != .Began { return }
        
        let touchPoint = gestureRecognizer.locationInView(self.touristMap)
        let touchMapCoordinate = touristMap.convertPoint(touchPoint, toCoordinateFromView: touristMap)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        touristMap.addAnnotation(annotation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveMapRegion() {
//        touristMap.region
    }
    
    func fetchMapRegion() {
        
    }
}

