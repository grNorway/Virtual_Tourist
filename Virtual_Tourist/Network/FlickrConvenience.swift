//
//  FlickrConvenience.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/12/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import Foundation
import MapKit
import CoreData

extension FlickrClient{
    
    func getPhotosFromFlickr(pin: Pin , completionHandlerForGetPhotosFromFlickrDownloadedItems: @ escaping (_ success: Bool , _ downloadedItems: Int , _ errorString: String?) -> (), completionHandlerForGetPhotosFromFlickrFinishDownloading: @escaping (_ success: Bool, _ errorString : String? ) -> ()){
        
        connectToFlickrAPI(pin: pin) { (success, photoArray, errorString) in
            if success{
                self.getNumberOfDownloadedPhotos(pin: pin, photoArray: photoArray!, completionHandlerForGetNumberOfDownloadedPhotos: { (success, downloadedItems, photoArray, errorString) in
                    if success{
                        
                        completionHandlerForGetPhotosFromFlickrDownloadedItems(true, downloadedItems, nil)
                        
                        self.downloadImageData(pin: pin, photoArray: photoArray!, completionHandlerForDownloadImageData: { (success, errorString) in
                            if success {
                                completionHandlerForGetPhotosFromFlickrFinishDownloading(true, nil)
                            }else{
                                completionHandlerForGetPhotosFromFlickrFinishDownloading(false, errorString!)
                            }
                        })
                    }else{
                        completionHandlerForGetPhotosFromFlickrDownloadedItems(false, 0, errorString!)
                    }
                })
            }else{
               completionHandlerForGetPhotosFromFlickrDownloadedItems(false, 0, errorString!)
            }
        }
    }
    
    
    // Connects to Flickr API and returns a arrayOf Photos
    private func connectToFlickrAPI(pin:Pin , _ completionHandlerForConnectToFlickrAPI: @escaping (_ success : Bool , _ resultsArray: [[String : AnyObject]]? , _ error: String?) -> ()){
        
        Constants.FlickrParameterValues.pageValue = "\(arc4random_uniform(40) + 1)"
        
        let parameters = [Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                          Constants.FlickrParameterKeys.ApiKey : Constants.FlickrParameterValues.ApiKeyValue,
                          Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.SafeSearchValue,
                          Constants.FlickrParameterKeys.latitude : pin.latitude,
                          Constants.FlickrParameterKeys.longitude : pin.longitude,
                          Constants.FlickrParameterKeys.PerPage : Constants.FlickrParameterValues.PerPageValue,
                          Constants.FlickrParameterKeys.page : Constants.FlickrParameterValues.pageValue,
                          Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.ExtrasURL_NValue,
                          Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.FormatValue,
                          Constants.FlickrParameterKeys.NoJsonCallBack : Constants.FlickrParameterValues.NoJsonCallBackValue,
                          ] as [String : AnyObject]
        
        let _ = taskForGetMethod(parameters: parameters) { (result, nsError) in
            
            guard nsError == nil else {
                completionHandlerForConnectToFlickrAPI(false, nil, nsError!.localizedDescription)
                return
            }
            
            if let resultsPhotos = result![Constants.FlickrResponseKeys.Photos] as? [String: AnyObject],let resultsArray = resultsPhotos[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] {
                completionHandlerForConnectToFlickrAPI(true, resultsArray, nil)
            }else{
                completionHandlerForConnectToFlickrAPI(false, nil, NetworkErrors.FlickrResponseNoKey)
            }
            
        }
    }
    
    
    //Gets the number of the photos that will be downloaded in total
    private func getNumberOfDownloadedPhotos(pin:Pin,photoArray: [[String:AnyObject]], completionHandlerForGetNumberOfDownloadedPhotos: @escaping(_ success: Bool ,_ downloadedItem: Int, _ photoArray: [[String:AnyObject]]?, _ errorString: String?) -> ()){
        
        guard !photoArray.isEmpty else {
            print("Array Is Empty")
            completionHandlerForGetNumberOfDownloadedPhotos(false, 0, nil, NetworkErrors.FlickrReturn0Results)
            return
        }
        
        completionHandlerForGetNumberOfDownloadedPhotos(true, photoArray.count, photoArray, nil)
        
    }
    
    
    private func downloadImageData(pin:Pin , photoArray : [[String:AnyObject]], completionHandlerForDownloadImageData: @escaping (_ finished: Bool ,_ errorString:String?) -> ()){
       
        for dictionary in photoArray {
            
            guard let URLString = dictionary[Constants.FlickrResponseKeys.URL_N] as? String else {
                completionHandlerForDownloadImageData(false, NetworkErrors.FLickrInternalError)
                return
            }
            
            stack.mainContext.perform {
                self.downloadImage(imagePath: URLString, completionHandlerForDownloadImage: { (data, errorString) in
                    
                    if errorString != nil {
                        completionHandlerForDownloadImageData(false, "")
                        return
                    }else{
        
                        let pinSaved  = self.checkForDeletedPin(stack: self.stack, pin: pin)
                        
                        guard pinSaved == true else{
                            print("Pin is Deleted")
                            completionHandlerForDownloadImageData(false, "")
                            return
                        }
                        
                        self.stack.mainContext.performAndWait {
                            let _ = PhotoFrame(pin: pin, imageData: data! as NSData, context: self.stack.mainContext)
                            self.stack.saveChanges()
                            print("Download Photos OK")
                        }
                    }
                })
            }
            
            
        }
        
        completionHandlerForDownloadImageData(true, nil)
    }
    
    // ----- Helper Functions ----- //
    
    // Check for deleted pin
    private func checkForDeletedPin(stack : CoreDataStack , pin : Pin) -> Bool {
        
        var pinCoordinates = CLLocationCoordinate2D()
        stack.mainContext.performAndWait {
            pinCoordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Pin")
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let predicateLatitude = NSPredicate(format: "latitude = %lf", pinCoordinates.latitude)
        let predicateLongitude = NSPredicate(format: "longitude = %lf", pinCoordinates.longitude)
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [predicateLatitude,predicateLongitude])
        
        var results = [Pin]()
        stack.mainContext.performAndWait {
            do{
                results = try self.stack.mainContext.fetch(request) as! [Pin]
                print("Results Predicate : \(results.count)")
            }catch{
                print("Error Checking Deleted Pin")
            }
        }
        
        if results.count == 0 {
            return false
        }else{
            return true
        }
    }
    
    private func downloadImage(imagePath: String , completionHandlerForDownloadImage:@escaping (_ imageData : Data? , _ errorString: String?) -> ()){
        let session = URLSession.shared
        
        guard let imgURL = URL(string: imagePath) else {
            completionHandlerForDownloadImage(nil, "Error URL Download image")
            return
        }
        let request : URLRequest = URLRequest(url: imgURL)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if error != nil {
                completionHandlerForDownloadImage(nil, "Error ConpletionHandlerDownloadImage : \(error!.localizedDescription)")
            }else{
                completionHandlerForDownloadImage(data, nil)
            }
        }
        task.resume()
        
    }
    
}










