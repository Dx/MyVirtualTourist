//
//  TravelLocationsMapViewController.swift
//  MyVirtualTourist
//
//  Created by Dx on 06/10/15.
//  Copyright © 2015 Palmera. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var hintContainerView: UIView!

    var mapRegion: MapRegion?
    var currentState: EditState = .AddPin
    var isInitialLoad = true
    let flickr = FlickrClient()
    
    enum EditState {
        case AddPin
        case EditPins
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        hintContainerView.hidden = true
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "onEditClick")
        self.navigationItem.rightBarButtonItem = editButton
        
        isInitialLoad = false
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        
        addLongPressGesture()
        
        setMapRegion()
        setPinsOnMap()
    }
    
    func addLongPressGesture() {
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "longPress:")
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    func onEditClick() {
        hintContainerView.hidden = false
        
        self.hintContainerView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.view.frame.size.height, self.view.frame.size.width, 80)
        
        UIView.animateWithDuration(0.5, animations: {
            self.mapContainerView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 64.0 - 80, self.view.frame.size.width, self.view.frame.size.height)
            
            self.hintContainerView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.view.frame.size.height - 80, self.view.frame.size.width, 80)
        })
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "onDoneClick")
        self.navigationItem.rightBarButtonItem = doneButton
        
        currentState = .EditPins
    }
    
    func onDoneClick() {
        // Animate
        UIView.animateWithDuration(0.5, animations: {
            
            self.mapContainerView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 64, self.view.frame.size.width, self.view.frame.size.height - 64)
            
            self.mapView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 64, self.view.frame.size.width, self.view.frame.size.height)
            
            self.hintContainerView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.view.frame.size.height, self.view.frame.size.width, 80)
            },
            completion: {
                (value: Bool) in
                self.hintContainerView.hidden = true
        })
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "onEditClick")
        self.navigationItem.rightBarButtonItem = editButton
        
        currentState = .AddPin
    }
    
    // MARK: - Shared Context
    
    lazy var sharedContext: NSManagedObjectContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    // MARK: - MapRegion functions
    
    func setMapRegion() {

        let regions = fetchMapRegions()
        if regions.count > 0 {
            
            self.mapRegion = regions[0]
            
            self.mapView.region = regions[0].region
        }
    }
    
    func saveMapRegion() {
        
        if isInitialLoad { return }
        
        if self.mapRegion != nil {

            self.mapRegion!.latitude = self.mapView.region.center.latitude
            self.mapRegion!.longitude = self.mapView.region.center.longitude
            self.mapRegion!.latitudeDelta = self.mapView.region.span.latitudeDelta
            self.mapRegion!.longitudeDelta = self.mapView.region.span.longitudeDelta
            
        } else {
            var dict = [String: AnyObject]()
            dict[MapRegion.Keys.latitude] = self.mapView.region.center.latitude
            dict[MapRegion.Keys.longitude] = self.mapView.region.center.longitude
            dict[MapRegion.Keys.latitudeDelta] = self.mapView.region.span.latitudeDelta
            dict[MapRegion.Keys.longitudeDelta] = self.mapView.region.span.longitudeDelta
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
        
        if let error = error {
            print("Unresolved error \(error), \(error.userInfo)", terminator: "")
            abort()
        }
        
        return results as? [MapRegion] ?? [MapRegion]()
    }

    // MARK: - Pins
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        selectPin(mapView, view: view)
    }
    
    func selectPin(mapView: MKMapView, view: MKAnnotationView) {
        let annotation: MKAnnotation = view.annotation!
        
        let pin: Pin? = fetchPin(atCoordinate: annotation.coordinate)
        
        switch currentState {
        case .AddPin:
            let storyboard = UIStoryboard (name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewControllerWithIdentifier("PhotoAlbumControllerID") as! PhotoAlbumViewController
            controller.pin = pin
            self.navigationController?.pushViewController(controller, animated: true)
            
        case .EditPins:
            if let pin = pin {
                deletePin(pin)
            }
            
            mapView.removeAnnotation(annotation)
        }
    }
    
    func setPinsOnMap() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        
        let pins = fetchAllPins()
        
        var annotationsToAdd = [MKAnnotation]()
        for pin in pins {
            annotationsToAdd.append(pin.annotation)
        }
        
        mapView.addAnnotations(annotationsToAdd)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.setNeedsDisplay()
        }
    }
    
    func fetchAllPins() -> [Pin] {
        
        let errorPointer: NSErrorPointer = nil
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: false), NSSortDescriptor(key: "longitude", ascending: false)]
        let results: [AnyObject]?
        
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch let error as NSError {
            errorPointer.memory = error
            results = nil
        }
        
        if errorPointer != nil {
            print("Error in fetchAllPins(): \(errorPointer)")
        }
        
        return results as? [Pin] ?? [Pin]()
    }
    
    func deletePin(pin: Pin) {
        sharedContext.deleteObject(pin)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func fetchPins() -> [Pin] {
        var error: NSError?
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: false)]
        
        let results: [AnyObject]?
        
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            results = nil
        }
        
        if let error = error {
            print("Unresolved error \(error), \(error.userInfo)", terminator: "")
            abort()
        }
        
        if let results = results {
            return (results as? [Pin])! // ?? [Pin]()
        } else {
            return [Pin]()
        }
    }
    
    func fetchPin(atCoordinate coordinate: CLLocationCoordinate2D) -> Pin? {
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: false), NSSortDescriptor(key: "longitude", ascending: false)]
        let predicateLat = NSPredicate(format: "latitude == %@", NSNumber(double: coordinate.latitude))
        let predicateLon = NSPredicate(format: "longitude == %@", NSNumber(double: coordinate.longitude))
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predicateLat, predicateLon])
        fetchRequest.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error.memory = error1
            results = nil
        }
        
        if error != nil {
            print("Error in fetchPin(): \(error)")
        }
        
        if let result = results {
            return (result[0] as? Pin)!
        } else {
            return nil
        }
    }
    
    // MARK: - Map functions
    func longPress(gestureRecognizer : UIGestureRecognizer){
        
        switch currentState {
        case .AddPin:
            if gestureRecognizer.state != .Began { return }
        
            let touchPoint = gestureRecognizer.locationInView(self.mapView)
            let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
        
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            
            let viewPoint: CGPoint = gestureRecognizer.locationInView(self.mapView)
            
            let pin = createPinAtPoint(viewPoint)
            
            self.flickr.searchPhotosBy2DCoordinates(pin) {
                success, error, imageMetadata in
                if success == true {
                    Photo.initPhotosFrom(imageMetadata, forPin: pin)
                }
            }
        case .EditPins:
            return
        }
    }
    
    func createPinAtPoint(viewPoint: CGPoint) -> Pin {
        
        let mapPoint: CLLocationCoordinate2D = self.mapView.convertPoint(viewPoint, toCoordinateFromView: self.mapView)
        
        let pin: Pin = createPinAtCoordinate(latitude: mapPoint.latitude, longitude: mapPoint.longitude)
        
        showPinOnMap(pin)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        return pin
    }
    
    func showPinOnMap(pin: Pin) {
        
        var annotations = [MKPointAnnotation]()
        annotations.append(pin.annotation)
        
        self.mapView.addAnnotations(annotations)
        self.mapView.setNeedsDisplay()
    }
    
    func createPinAtCoordinate(latitude latitude: Double, longitude: Double) -> Pin {
        var dict = [String: AnyObject]()
        dict[Pin.Keys.latitude] = latitude
        dict[Pin.Keys.longitude] = longitude
        let pin = Pin(dictionary: dict, context: sharedContext)
        return pin
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Changes: \(mapView.region.center.latitude, mapView.region.center.longitude, mapView.region.center.longitude)")
        saveMapRegion()
    }

    // MARK: - Others
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

