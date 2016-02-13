//
//  FlickrClient.swift
//  MyVirtualTourist
//
//  Created by Dx on 01/02/16.
//  Copyright © 2016 Palmera. All rights reserved.
//

import Foundation
import UIKit

protocol flickrDelegate {
    func numberOfPhotosToReturn(flickr: FlickrClient, count: Int)
}

class FlickrClient {
    
    static let BOUNDING_BOX_HALF_WIDTH = 0.5
    static let BOUNDING_BOX_HALF_HEIGHT = 0.5
    static let LATITUDE_MIN = -90.0
    static let LATITUDE_MAX = 90.0
    static let LONGITUDE_MIN = -180.0
    static let LONGITUDE_MAX = 180.0
    
    /* Flickr REST api constants */
    struct Constants {
        static let BASE_URL: String = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME: String = "flickr.photos.search"
        static let API_KEY: String = "2d4ee23b59c07852240a4a453aaa347f"
        static let EXTRAS: String = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT: String = "json"
        static let NO_JSON_CALLBACK: String = "1"
    }
    
    /* Keys for the dictionary returned by the Flickr api. */
    struct FlickrDictionaryKeys {
        static let URL: String = "url_m"
        static let ID: String = "id"
        static let TITLE: String = "title"
    }
    
    /* Keys for dictionary returned by the searchFlickrForImageMetadataWith method. */
    struct FlickrImageMetadataKeys {
        static let URL: String = "url"
        static let ID: String = "id"
        static let TITLE: String = "title"
    }
    
    var delegate: flickrDelegate?
    
    static let MAX_PHOTOS_TO_FETCH = 24

    func searchFlickrForImageMetadataWith(methodArguments: [String : AnyObject], page: Int32, completionHandler: (success: Bool, error: NSError?, arrayOfDictionaries: [[String: AnyObject?]]?, nextPage: Int32) -> Void) {
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Could not complete http request to Flickr service. \(error)")
                completionHandler(success: false, error: error, arrayOfDictionaries: nil, nextPage: page)
            } else {
                
                let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        let pageLimit = min(totalPages, 40)
                        
                        var pageNum: Int = Int(page)
                        if pageNum > pageLimit {
                            pageNum = 1
                        }
                        
                        self.searchFlickrForImageMetadataByPageWith(methodArguments, pageNumber: pageNum) { success, error, arrayOfDicts in
                            completionHandler(success: success, error: error, arrayOfDictionaries: arrayOfDicts, nextPage: Int32(++pageNum))
                        }
                    } else {
                        print("Cant find key 'pages' in response to the Flickr api search request")
                        completionHandler(success: false, error: nil, arrayOfDictionaries: nil, nextPage: page)
                    }
                } else {
                    print("Cant find key 'photos' in response to the Flickr api search request")
                    completionHandler(success: false, error: nil, arrayOfDictionaries: nil, nextPage: page)
                }
            }
        }
        
        task.resume()
    }
    
    func searchFlickrForImageMetadataByPageWith(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (success: Bool, error: NSError?, arrayOfDicts: [[String: AnyObject?]]?) -> Void) {
        
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Could not complete http request to Flickr service. \(error)")
                completionHandler(success: false, error: error, arrayOfDicts: nil)
            } else {
                let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    
                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            
                            var dictionariesToReturn = [[String: AnyObject?]]()
                            
                            let numPhotosToFetch = min(/*totalPhotosVal*/ photosArray.count, FlickrClient.MAX_PHOTOS_TO_FETCH)
                            
                            print("Flickr.searchFlickrForImageMetadataByPageWith reports \(photosArray.count) photos found on page \(pageNumber).")
                            
                            if let delegate = self.delegate {
                                delegate.numberOfPhotosToReturn(self, count: numPhotosToFetch)
                            }
                            
                            for i in 0..<numPhotosToFetch {
                                let photoDictionary = photosArray[i] as [String: AnyObject]
                                
                                let photoTitle = photoDictionary[FlickrDictionaryKeys.TITLE] as? String
                                let imageUrlString = photoDictionary[FlickrDictionaryKeys.URL] as? String
                                let id = photoDictionary[FlickrDictionaryKeys.ID] as? String
                                
                                var imageMetadataDict = [String: AnyObject?]()
                                imageMetadataDict["title"] = photoTitle
                                imageMetadataDict["url"] = imageUrlString
                                imageMetadataDict["id"] = id
                                dictionariesToReturn.append(imageMetadataDict)
                            }
                            
                            completionHandler(success: true, error: nil, arrayOfDicts: dictionariesToReturn)
                        } else {
                            print("Cant find key 'photo' in response to the Flickr api search request.")
                            completionHandler(success: false, error: nil, arrayOfDicts: nil)
                        }
                    } else {
                        completionHandler(success: true, error: nil, arrayOfDicts: nil)
                    }
                } else {
                    print("Cant find key 'photos' in response to the Flickr api search request.")
                    completionHandler(success: false, error: nil, arrayOfDicts: nil)
                }
            }
        }
        
        task.resume()
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    func searchPhotosBy2DCoordinates(pin: Pin,
        completionHandler: (success: Bool, error: NSError?, imageMetadata: [[String: AnyObject?]]?) -> Void) {
            
        let methodArguments = [
            "method": FlickrClient.Constants.METHOD_NAME,
            "api_key": FlickrClient.Constants.API_KEY,
                
            "bbox": getBoundingBox(pin.coordinate.latitude, longitude: pin.coordinate.longitude),
                
            "safe_search": FlickrClient.Constants.SAFE_SEARCH,
            "extras": FlickrClient.Constants.EXTRAS,
            "format": FlickrClient.Constants.DATA_FORMAT,
            "nojsoncallback": FlickrClient.Constants.NO_JSON_CALLBACK
        ]
        
        let flickrPage = pin.flickrPage
        
        self.searchFlickrForImageMetadataWith(methodArguments, page: flickrPage.intValue) {
            success, error, metaData, nextPage in
            
            dispatch_async(dispatch_get_main_queue()) {
                pin.flickrPage = NSNumber(int: nextPage)
            }
            
            if success == true {
                completionHandler(success: true, error: nil, imageMetadata: metaData)
            } else {
                completionHandler(success: false, error: error, imageMetadata: nil)
            }
        }
    }
    
    func getBoundingBox(latitude: Double, longitude: Double) -> String {
        let bottomLeftLongitude = max(longitude - FlickrClient.BOUNDING_BOX_HALF_WIDTH, FlickrClient.LONGITUDE_MIN)
        let bottomLeftLatitude = max(latitude - FlickrClient.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.LATITUDE_MIN)
        let topRightLongitude = min(longitude + FlickrClient.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.LONGITUDE_MAX)
        let topRightLatitude = min(latitude + FlickrClient.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.LATITUDE_MAX)
        
        return "\(bottomLeftLongitude),\(bottomLeftLatitude),\(topRightLongitude),\(topRightLatitude)"
    }
}