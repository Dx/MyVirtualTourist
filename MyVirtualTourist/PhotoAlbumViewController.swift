//
//  PhotoAlbumViewController.swift
//  MyVirtualTourist
//
//  Created by Dx on 24/10/15.
//  Copyright © 2015 Palmera. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, flickrDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var noImagesLabel: UILabel!
    
    var newCollectionButton: UIBarButtonItem? = nil
    
    var pin:Pin?
    
    let flickr = FlickrClient()
    
    private let sectionInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    
    private var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0, 0, 40, 40)) as UIActivityIndicatorView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPhotos()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        // Setting delegates
        flickr.delegate = self
        fetchedResultsController.delegate = self
        
        if let pin = pin {
            showPinOnMap(pin)
        }
        
        // configure the toolbar items
        let flexButtonLeft = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        newCollectionButton = UIBarButtonItem(title: "New Collection", style: .Plain, target: self, action: "onNewCollectionButtonTap")
        let flexButtonRight = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        self.setToolbarItems([flexButtonLeft, newCollectionButton!, flexButtonRight], animated: true)
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        if let _ = pin {
            newCollectionButton!.enabled = true
        }
    }
    
    func onNewCollectionButtonTap() {
        if let pin = pin {
            for photo in pin.photos {
                photo.deletePhoto()
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        resetPhotos()
    }
    
    func resetPhotos() {
        
        newCollectionButton!.enabled = false
        
        if let pin = self.pin {
            self.flickr.searchPhotosBy2DCoordinates(pin) {
                success, error, imageMetadata in
                if success == true {
                    Photo.initPhotosFrom(imageMetadata, forPin: pin)
                    
                    self.newCollectionButton!.enabled = true
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView.reloadData()
                    }
                } else {

                    if let error = error {
                        _ = error.localizedDescription
                        print("error \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func showPinOnMap(pin: Pin) {
        var annotations = [MKPointAnnotation]()
        annotations.append(pin.annotation)
        
        self.mapView.addAnnotations(annotations)
        
        let span = MKCoordinateSpanMake(0.15, 0.15)
        self.mapView.region.span = span
        
        self.mapView.setCenterCoordinate(pin.coordinate, animated: false)
        
        self.mapView.setNeedsDisplay()
    }
    
    // MARK: UICollectionViewDataSource protocol
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        let count = sectionInfo.numberOfObjects
        
        if count > 0 {
            self.noImagesLabel.hidden = true
            self.collectionView.hidden = false
        } else {
            self.noImagesLabel.hidden = false
            self.collectionView.hidden = true
        }
        
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PictureCellId", forIndexPath: indexPath) as! PictureCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: PictureCell, atIndexPath indexPath: NSIndexPath) {
        
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        photo.getImage( { success, error, image in
            if success {
                dispatch_async(dispatch_get_main_queue()) {
                    cell.imageView.image = image
                }
            } else {
                cell.imageView.image = nil
            }
        })
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let widthSpaces: CGFloat = (4 * sectionInsets.left) + (4 * sectionInsets.right)
        let cellWidth = (collectionView.frame.size.width -  widthSpaces ) / 4
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // MARK: UICollectionViewDelegate protocol
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        photo.deletePhoto()
        
        self.collectionView.reloadData()
    }
    
    func startActivityIndicator() {
        self.activityIndicator.center = self.view.center
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        self.view.addSubview(self.activityIndicator)
        
        self.activityIndicator.startAnimating()
    }
    
    func stopActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.stopAnimating()
        }
    }

    // MARK: - Core Data
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    // MARK: - Fetched results controller
    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        if let pin = self.pin {
            fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        } else {
            print("self.pin == nil in PhotoAlbumViewController")
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:
            self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    } ()
    
    func fetchPhotos() {
        var error: NSError? = nil
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("Error \(error), \(error.userInfo)")
        }
    }

    // MARK: - Flickr Client delegate
    func numberOfPhotosToReturn(flickr: FlickrClient, count: Int) {
        print("flickrDelegate protocol reports \(count) images will be downloaded.")
    }
}