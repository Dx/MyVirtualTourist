//
//  Picture.swift
//  MyVirtualTourist
//
//  Created by Dx on 12/10/15.
//  Copyright © 2015 Palmera. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Picture : NSManagedObject {
    struct InitKeys {
        static let pin: String = "pin"
        static let url: String = "url"
        static let title: String = "title"
        static let id: String = "id"
    }
    
    @NSManaged var pin: Pin?
    @NSManaged var id: String?
    @NSManaged var title: String?
    @NSManaged var url: String?
    
    // MARK: - Core Data
    static var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        pin = dictionary[InitKeys.pin] as? Pin
        url = dictionary[InitKeys.url] as? String
        title = dictionary[InitKeys.title] as? String
        id = dictionary[InitKeys.id] as? String
    }
    
    func getImage(completion: (success: Bool, error: NSError?, image: UIImage?) -> Void ) {
        
        if let id = self.id {
            if let image = getImageFromFileSystem(id) {
                print("image loaded from file system")
                
                completion(success: true, error: nil, image: image)
                return
            }
        }
        
        if let url = self.url {
            self.downloadImageFrom(url) { success, error, theImage in
                if success {
                    if let theImage = theImage {
                        self.cacheImageAndWriteToFile(theImage)
                    }
                    print("image downloaded")
                    completion(success: true, error: nil, image: theImage)
                    return
                } else {
                    self.downloadImageFrom(url) { success, error, theImage in
                        if success {
                            if let theImage = theImage {
                                self.cacheImageAndWriteToFile(theImage)
                            }
                            print("image downloaded")
                            completion(success: true, error: nil, image: theImage)
                            return
                        } else {
                            print("Image download from Flickr service failed")
                            completion(success: false, error: error, image: nil)
                        }
                    }
                }
            }
        }
    }
    
    func cacheImageAndWriteToFile(theImage: UIImage) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            if let id = self.id {
                let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
                dispatch_async(backgroundQueue, {
                    self.saveImageToFileSystem(id, image: theImage)
                })
            }
        }
    }
    
    func saveImageToFileSystem(filename: String, image: UIImage?) {
        if let image = image {
            let imageData = UIImageJPEGRepresentation(image, 1)
            let path = pathForImageFileWith(filename)
            if let path = path {
                imageData!.writeToFile(path, atomically: true)
            }
        }
    }
    
    func downloadImageFrom(imageUrlString: String?, completion: (success: Bool, error: NSError?, image: UIImage?) -> Void) {
        
        let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        dispatch_async(backgroundQueue, {

            let imageURL = NSURL(string: imageUrlString!)
            if let imageData = NSData(contentsOfURL: imageURL!) {
                
                if let picture = UIImage(data: imageData) {
                    completion(success: true, error: nil, image: picture)
                }
                else {
                    print("Cannot convert image data.")
                    completion(success: false, error: nil, image: nil)
                }
                
            } else {
                print("Image does not exist at \(imageURL)")
                completion(success: false, error: nil, image: nil)
            }
        })
    }

    
    func getImageFromFileSystem(filename: String) -> UIImage? {
        let path = pathForImageFileWith(filename)
        if let path = path {
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                let imageData = NSFileManager.defaultManager().contentsAtPath(path)
                if let imageData = imageData {
                    let image = UIImage(data: imageData)
                    return image
                }
            }
        }
        return nil
    }
    
    func pathForImageFileWith(filename: String) -> String? {

        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathArray = [dirPath, filename]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
        return fileURL.path
    }
    
    class func initPhotosFrom(imageMetadata: [[String: AnyObject?]]?, forPin: Pin?) {
        dispatch_async(dispatch_get_main_queue()) {
            
            var dict = [String: AnyObject]()
            dict[Picture.InitKeys.pin] = forPin
            
            if let imageMetadata = imageMetadata {
                for metadataDictionary in imageMetadata {

                    if let url = metadataDictionary[FlickrClient.FlickrImageMetadataKeys.URL] as? String {
                        dict[Picture.InitKeys.url] = url
                    } else {
                        dict[Picture.InitKeys.url] = nil
                    }
                    
                    if let title = metadataDictionary[FlickrClient.FlickrImageMetadataKeys.TITLE] as? String {
                        dict[Picture.InitKeys.title] = title
                    } else {
                        dict[Picture.InitKeys.title] = nil
                    }
                    
                    if let id = metadataDictionary[FlickrClient.FlickrImageMetadataKeys.ID] as? String {
                        dict[Picture.InitKeys.id] = id
                    } else {
                        dict[Picture.InitKeys.id] = nil
                    }
                    
                    let picture = Picture(dictionary:dict, context: Picture.sharedContext)
                    
                    picture.getImage( { success, error, image in
                        dispatch_async(dispatch_get_main_queue()) {
                            if success {
                                print("successfully downloaded image \(picture.id): \(picture.title)")
                            } else {
                                print("error acquiring image \(picture.id): \(picture.title)")
                            }
                        }
                    })
                }
            }
            
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func deletePicture() {
        
        Picture.sharedContext.deleteObject(self)
        CoreDataStackManager.sharedInstance().saveContext()
    }
}