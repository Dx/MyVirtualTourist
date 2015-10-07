//
//  ViewController.swift
//  MyVirtualTourist
//
//  Created by Dx on 06/10/15.
//  Copyright © 2015 Palmera. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var touristMap: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "createPin:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        touristMap.addGestureRecognizer(longPressRecogniser)
    }
    
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
}

