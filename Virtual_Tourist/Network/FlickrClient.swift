//
//  FlickrClient.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/12/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import UIKit

class FlickrClient {
    
    //MARK: - Singleton Instance
    static var sharedInstance = FlickrClient()
    
    //MARK: - Properties
    let stack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    var session = URLSession.shared
    
    func taskForGetMethod(parameters : [String : AnyObject] , completionHandlerForGetMethod : @escaping(_ results: AnyObject?, _ error:NSError?) -> ()){
        
        let request = NSMutableURLRequest(url: flickrURLFromParameters(parameters: parameters))
        
        let task = session.dataTask(with: request as! URLRequest) { (data, response, error) in
            
            func displayError(errorString: String){
                print(errorString)
                let userInfo = [NSLocalizedDescriptionKey : errorString]
                completionHandlerForGetMethod(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
            }
            
            guard error == nil else {
                displayError(errorString: error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else{
                displayError(errorString: error!.localizedDescription)
                return
            }
            
            guard let data = data else{
                displayError(errorString: error!.localizedDescription)
                return
            }
            
            self.convertDataWithCompletionHandler(data: data, completionHandlerForConvertingData: completionHandlerForGetMethod)
            
        }
        task.resume()
    }
    
    //MARK: - Helpers Functions
    
    private func flickrURLFromParameters( parameters: [String: AnyObject] , withExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key,value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem)
        }
        
        return components.url!
    }
    
    
    
    private func convertDataWithCompletionHandler(data : Data , completionHandlerForConvertingData:@escaping (_ results: AnyObject? , _ error: NSError?) -> ()){
        
        var parsedResults : AnyObject! = nil
        do{
            parsedResults = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        }catch{
            let userInfo = [NSLocalizedDescriptionKey : "Could Not parse the data as JSON DATA : \(data)"]
            completionHandlerForConvertingData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertingData(parsedResults,nil)
    }
    
    
}





















