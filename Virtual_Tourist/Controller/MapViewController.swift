//
//  MapViewController.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/11/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    //MARK: - Segue
    
    private enum  Segue{
        static let LocationPhotos = "LocationPhotos"
    }
    
    //MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet weak var deleteLabel: UILabel!
    
    
    //MARK: Properties
    private var annotations = [Pin]()
    private var editingMode = false
    
    //MARK: - Core Data Properties
    var stack : CoreDataStack!
    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Virtual Tourist"
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSavedPins()
        longPressGesture()
    }

    // Adds a longPressGesture to add the pins on MapView
    private func longPressGesture(){
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPinByLongPress(byReactingTo:)))
        longPressGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGesture)
    }
    

    // Selector to addPinByLongPress add a MKPinAnnotationView and makes a Pin(MO)
    @objc private func addPinByLongPress(byReactingTo gesture: UILongPressGestureRecognizer){
        
        switch gesture.state{
        case .began:
            let touchLocation = gesture.location(ofTouch: 0, in: mapView)
            let locationCoordinates = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinates
            
            let pin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context:stack.mainContext )
            
            annotations.append(pin)
            mapView.addAnnotation(annotation)
            
        default:
            break
        }
        
        print(mapView.annotations.count)
    }
    
    
    // Fetches the saved pins from Core Data
    // First we remove them
    // Then fetch and load them
    private func fetchSavedPins(){
        
        mapView.removeAnnotations(mapView.annotations)
        
        stack.fetch(objects: "Pin", from: stack.mainContext, withSortDesciptorKey: "creationDate", ascending: true) { (results) in
            
            if let results = results as? [Pin]{
        
                self.annotations = results
                
                for result in results{
                    let annotation = MKPointAnnotation()
                    annotation.coordinate.latitude = result.latitude
                    annotation.coordinate.longitude = result.longitude
                    self.mapView.addAnnotation(annotation)
                }
                
            }
        }
        
        
    }
    
    
    // BarButtonItem - action Edit/Done to delete an pin
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        switch editingMode{
        case true:
            deleteLabel.isHidden = true
            mapView.bounds.origin.y = mapView.bounds.origin.y - deleteLabel.bounds.height
            editingMode = false
            editBarButton.title = "Edit"
            
        case false:
            deleteLabel.isHidden = false
            mapView.bounds.origin.y = mapView.bounds.origin.y + deleteLabel.bounds.height
            editingMode = true
            editBarButton.title = "Done"
            
        }
    }
    
    
  
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {return}
        
        switch identifier{
        case Segue.LocationPhotos:
            guard let locationPhotosViewController = segue.destination as? LocationPhotosViewController else {return}
            
            let selectedPin = sender as! Pin
            locationPhotosViewController.pin = selectedPin
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoFrame")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let predicate = NSPredicate(format: "pin = %@", selectedPin)
            fetchRequest.predicate = predicate
            
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.mainContext, sectionNameKeyPath: nil, cacheName: nil)
            
            locationPhotosViewController.fetchedResultsController = fetchedResultsController
            locationPhotosViewController.stack = stack
            
            let unfinishedPin : [String : Pin] = ["unfinishedPin": selectedPin]
            
            //MAKE CALL TO FLICKR
            if selectedPin.images?.count == 0 && selectedPin.hasReturned == true{
                
                selectedPin.hasReturned = false
                NotificationCenter.default.post(name: .addUnfinishedPinToAppDelegate, object: nil, userInfo: unfinishedPin)
                
                FlickrClient.sharedInstance.getPhotosFromFlickr(pin: selectedPin, completionHandlerForGetPhotosFromFlickrDownloadedItems: { (success, willDownloadPhotos, errorString) in
                    
                    if success{
                        print("Success number Of images willDownloadPhotos : \(willDownloadPhotos) ")
                        self.stack.mainContext.performAndWait {
                            selectedPin.numberOfImages = Int16(willDownloadPhotos)
                        }
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .pinNumberOfImages, object: nil)
                        }
                        
                    }else{
                        NotificationCenter.default.post(name: .removeUnfinishedPinFromAppDelegate, object: nil, userInfo: unfinishedPin)
                        print("Not Success willDownloadPhotos \(errorString!)")
                        DispatchQueue.main.async {
                            let errorString : [String : String] = ["errorString":errorString!]
                            NotificationCenter.default.post(name: .errorMessageToAlertController, object: nil, userInfo: errorString)
                            NotificationCenter.default.post(name: .enableLoadMorePictures, object: nil)
                        }
              
                        self.stack.mainContext.perform {
                            selectedPin.hasReturned = true
                        }
                    }
                    
                }, completionHandlerForGetPhotosFromFlickrFinishDownloading: { (success, errorString) in
                    if success{
                        NotificationCenter.default.post(name: .removeUnfinishedPinFromAppDelegate, object: nil, userInfo: unfinishedPin)
                        print("Success DownloadingAllPhotos")
                        self.stack.mainContext.performAndWait {
                            selectedPin.hasReturned = true
                        }
                        
                        DispatchQueue.main.async {
                            
                            NotificationCenter.default.post(name: .allowCellSelection, object: nil)
                            NotificationCenter.default.post(name: .enableLoadMorePictures, object: nil)
                        }
                        
                    }else{
                        NotificationCenter.default.post(name: .removeUnfinishedPinFromAppDelegate, object: nil, userInfo: unfinishedPin)
                        print("Unable to Download Photos")
                        self.stack.mainContext.performAndWait {
                            selectedPin.hasReturned = true
                        }
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .errorFinishingTheDownloadingPhotos, object: nil)
                            guard errorString != "" else { return }
                            let errorString : [String:String] = ["errorString":errorString!]
                            NotificationCenter.default.post(name: .errorMessageToAlertController, object: nil, userInfo: errorString)
                        }  
                    }
                })
                
            }else if !selectedPin.hasReturned{
                print("selected Pin has not returned from Flickr Get Method")
            }else if selectedPin.hasReturned{
                print("selected Pin has Returned from Flickr Get Method")
                if Int(selectedPin.numberOfImages) > selectedPin.images!.count{
                    stack.mainContext.performAndWait {
                        selectedPin.numberOfImages = Int16(selectedPin.images!.count)
                    }
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .enableCellsAndLoadMorePicturesButton, object: nil)
                }
                
            }
            
        default:
            break
        }
    }
   

}

//MARK: - MKMapViewDelegate
extension MapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "locationPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.isEnabled = true
            pinView.animatesDrop = false
            pinView.canShowCallout = false
            
            annotationView = pinView
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annotationCoordinates = view.annotation?.coordinate{
            
            let index = annotations.index(where: { (annotation) -> Bool in
                return ( annotation.latitude == annotationCoordinates.latitude && annotation.longitude == annotationCoordinates.longitude )
            })
            
            let pin = annotations[index!]
            mapView.deselectAnnotation(view.annotation, animated: true)
            
            switch editingMode{
            case true:
                let unfinishedPin : [String:Pin] = ["unfinishedPin":pin]
                stack.deleteCoreDataObject(object: pin, from: stack.mainContext)
                //TODO: - Remove from app delegate pin
                NotificationCenter.default.post(name: .removeUnfinishedPinFromAppDelegate, object: nil, userInfo: unfinishedPin)
                fetchSavedPins()
            case false:
                performSegue(withIdentifier: Segue.LocationPhotos, sender: pin)
            
            }
        }
    }
}










