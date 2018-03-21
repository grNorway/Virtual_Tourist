//
//  LocationPhotosViewController.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/12/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class LocationPhotosViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!    
    @IBOutlet weak var loadMorePicturesBtn: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    //MARK: - Core Data Properties
    var pin : Pin!
    var stack : CoreDataStack!
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    
    //MARK: - FetchedResultsControllerDelegate Properties
    private var insertIndexPaths: [IndexPath]!
    private var deleteIndexPaths: [IndexPath]!
    private var updateIndexPaths: [IndexPath]!
    
    //MARK: - Properties
    fileprivate let insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    fileprivate var itemsPerRow : CGFloat = 3
    private var editingMode = false
    private var selectedImages = [PhotoFrame]()
    
    
    private enum notificationsEnabled {
        case Enabled , Disabled
    }
    
    private enum allowance {
        case Enabled , Disable
    }
    
    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        print("Pin in LocationPhotosVC : \(pin!)")
        print("frc : \(fetchedResultsController!)")
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationsObservers(are: .Enabled)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notificationsObservers(are: .Disabled)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    deinit {
        print("Deinit LocationPhotosViewController")
        fetchedResultsController.delegate = nil
        if Int(pin.images!.count) == pin.numberOfImages {
            stack.mainContext.performAndWait {
                self.pin.hasReturned = true
                
            }
            
        }
    }
    
    func setupView(){
        allowSelectionOnCells(is: .Disable)
        fetchedResultsController.delegate = self
        executeSearch()
        setupMap()
    }
    
    // Add / Remove Observers on Notifications
    private func notificationsObservers(are observers: notificationsEnabled){
        switch observers{
        case .Enabled:
            NotificationCenter.default.addObserver(self, selector: #selector(pinNumberOfImagesChanged), name: .pinNumberOfImages, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(loadAlertMsg(_:)), name: .errorMessageToAlertController, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(enableCellsSelection), name: .allowCellSelection, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(enableLoadMorePicturesButton), name: .enableLoadMorePictures, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateNumberOfItemsErrorTimeOut), name: .errorFinishingTheDownloadingPhotos, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(enableCellsAndLoadButton), name: .enableCellsAndLoadMorePicturesButton, object: nil)
            
        case .Disabled:
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func notificationsForEditedObject(are observers:notificationsEnabled){
        switch observers{
        case .Enabled :
            NotificationCenter.default.addObserver(self, selector: #selector(saveEditedObject), name: .UIApplicationWillTerminate, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(saveEditedObject), name: .UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(editEditedObject), name: .UIApplicationWillEnterForeground, object: nil)
        case .Disabled:
            NotificationCenter.default.removeObserver(self, name: .UIApplicationWillTerminate, object: nil)
            NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        }
        
    }
    
    @objc private func saveEditedObject(){
        stack.mainContext.perform{
            if !self.pin.hasReturned && self.pin.numberOfImages == self.pin.images!.count{
                self.pin.hasReturned = true
                self.stack.saveChanges()
            }
            
        }
    }
    
    @objc private func editEditedObject(){
        print("P I N editEditedObject() :\(pin)")
    }
    
    private func setupMap(){
        let annotation = MKPointAnnotation()
        let coordinates = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
        mapView.isUserInteractionEnabled = false
        mapView.setCenter(annotation.coordinate, animated: true)
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(annotation.coordinate, span)
        mapView.setRegion(region, animated: false)
    }
    
    @objc private func pinNumberOfImagesChanged(){
            self.collectionView.reloadData()
    }
    
    @objc private func loadAlertMsg(_ notification : Notification){
        
        guard let errorString = notification.userInfo?["errorString"] as? String else {return}
        
        guard errorString != "" else {return}
        
        let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func enableCellsSelection(){
        allowSelectionOnCells(is: .Enabled)
    }
    
    @objc private func enableLoadMorePicturesButton(){
        loadMorePhotosButton(is: .Enabled)
    }
    
    @objc private func enableCellsAndLoadButton(){
        
        loadMorePhotosButton(is: .Enabled)
        allowSelectionOnCells(is: .Enabled)
    }
    
    // Update the pin.numberOfItems since the call has been
    // Timed Out and the rest of the pictures will not download
    @objc private func updateNumberOfItemsErrorTimeOut(){
        if let pinImages = pin.images?.count , pinImages != 0 {
            pin.numberOfImages = Int16(pinImages)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.loadMorePhotosButton(is: .Enabled)
                self.allowSelectionOnCells(is: .Enabled)
            }
        }
    }
    
    
    private func allowSelectionOnCells(is allowance:allowance){
        switch allowance{
        case .Enabled:
            collectionView.allowsSelection = true
            collectionView.allowsMultipleSelection = true
        case .Disable:
            collectionView.allowsSelection = false
            collectionView.allowsMultipleSelection = false
        }
    }
    
    // sets up the loadMorePhotosButton isEnable
    private func loadMorePhotosButton(is allowance: allowance){
        DispatchQueue.main.async {
            switch allowance{
            case .Enabled :
                self.loadMorePicturesBtn.isEnabled = true
            case .Disable:
                self.loadMorePicturesBtn.isEnabled = false
            }
        }
        
    }
    
    //MARK: - loadMorePicuresBtb (Action)
    @IBAction func loadMorePicturesPressed(_ sender: UIButton) {
        switch editingMode{
        case true:
            deleteSelectedObjects()
        case false:
            
            allowSelectionOnCells(is: .Disable)
            loadMorePhotosButton(is: .Disable)
            notificationsForEditedObject(are: .Disabled)
            let results = fetchedResultsController.fetchedObjects!

            stack.mainContext.performAndWait {
                for result in results{
                    self.stack.mainContext.delete(result as! NSManagedObject)
                }
                pin.hasReturned = false
                pin.numberOfImages = 0
                self.stack.saveChanges()
            }
            
            let unfinishedPin : [String : Pin] = ["unfinishedPin": pin]
            NotificationCenter.default.post(name: .addUnfinishedPinToAppDelegate, object: nil, userInfo: unfinishedPin)
            
            FlickrClient.sharedInstance.getPhotosFromFlickr(pin: pin, completionHandlerForGetPhotosFromFlickrDownloadedItems: { (success, willDownloadPhotos, errorString) in
                
                if success{
                    print("Success number Of images willDownloadPhotos : \(willDownloadPhotos) ")
                    self.stack.mainContext.performAndWait {
                        self.pin.numberOfImages = Int16(willDownloadPhotos)
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
                        self.pin.hasReturned = true
                    }
                }
                
            }, completionHandlerForGetPhotosFromFlickrFinishDownloading: { (success, errorString) in
                if success{
                    print("Success DownloadingAllPhotos")
                    
                }else{
                    NotificationCenter.default.post(name: .removeUnfinishedPinFromAppDelegate, object: nil, userInfo: unfinishedPin)
                    print("Unable to Download Photos")
                    self.stack.mainContext.performAndWait {
                        self.pin.hasReturned = true
                    }
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .errorFinishingTheDownloadingPhotos, object: nil)
                        guard errorString != "" else { return }
                        let errorString : [String:String] = ["errorString":errorString!]
                        NotificationCenter.default.post(name: .errorMessageToAlertController, object: nil, userInfo: errorString)
                    }
                }
            })
        }
    }
    
    //MARK: - Delete Selected Objects
    private func deleteSelectedObjects(){
        notificationsForEditedObject(are: .Enabled)
        allowSelectionOnCells(is: .Disable)
        loadMorePhotosButton(is: .Disable)
        var resultsCount : Int = 0
        stack.fetch(objects: "PhotoFrame", from: stack.mainContext, withSortDesciptorKey: "creationDate", ascending: true) { (results) in
            
            guard let results = results as? [PhotoFrame] else{
                print("Error no Results from coreDataStack.Fetch()")
                return
            }
    
            for result in results {
                for selectedImage in self.selectedImages{
                    if result == selectedImage {
                        resultsCount += 1
                        self.stack.mainContext.performAndWait {
                            self.stack.mainContext.delete(result)
                        }
                        print("Deleted Object")
                    }else{
                        print("Not Equal")
                    }
                }
            }
        }
        
        getNumberOfItems(fetchedResults: resultsCount)
        selectedImages.removeAll()
        
        stack.saveChanges()
        editingMode = false
        loadMorePicturesBtn.setTitle("Load More Pictures", for: .normal)
        allowSelectionOnCells(is: .Enabled)
        loadMorePhotosButton(is: .Enabled)
        print("NumberOfImages : \(pin.numberOfImages) , pin.images.count : \(String(describing: pin.images?.count))")
        
    }
    
    // Update pin.numberOfImages
    private func getNumberOfItems(fetchedResults: Int){
        print(pin.numberOfImages)
        print(fetchedResults)
        pin.numberOfImages = pin.numberOfImages - Int16(fetchedResults)
    }
    
    // unselect Selected Cells
    private func unselectCollectionViewCells(at indexPath: IndexPath){
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell{
            if cell.deleteLabel.isHidden == false {
                cell.deleteLabel.isHidden = true
            }
        }
    }
    
    private func checkForEditedPin(if hasReturned:Bool){
        if !pin.hasReturned && pin.numberOfImages == 0{
            return
         
         }else if !pin.hasReturned && pin.numberOfImages == Int(pin.images!.count){
            stack.mainContext.performAndWait {
                pin.hasReturned = true
                let unfinishedPin : [String : Pin] = ["unfinishedPin": pin]
                NotificationCenter.default.post(name: .removeUnfinishedPinFromAppDelegate, object: nil, userInfo: unfinishedPin)
                NotificationCenter.default.post(name: .allowCellSelection, object: nil)
                NotificationCenter.default.post(name: .enableLoadMorePictures, object: nil)
                
            }
        }
    }
    

}

//MARK: - UICollectionViewDelegate
extension LocationPhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
            editingMode = true
            loadMorePicturesBtn.setTitle("Delete Selected Items", for: .normal)
            
            if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell{
                cell.deleteLabel.isHidden = false
            }
            
            let selectedPhotoFrame = fetchedResultsController.object(at: indexPath) as! PhotoFrame
            selectedImages.append(selectedPhotoFrame)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if editingMode{
            let selectedPhotoFrame = fetchedResultsController.object(at: indexPath) as! PhotoFrame
            if let index = selectedImages.index(of: selectedPhotoFrame){
                selectedImages.remove(at: index)
            }
            
            if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell{
                cell.deleteLabel.isHidden = true
            }
            
            guard selectedImages.count != 0 else{
                editingMode = false
                loadMorePicturesBtn.setTitle("Load More Pictures", for: .normal)
                return
            }
        }
        
    }
    
}

//MARK: - UICollectionViewDataSource
extension LocationPhotosViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
        if pin.hasReturned && pin.numberOfImages > Int16(pin.images!.count){
            print("1")
            return pin.images!.count
        }else{
            print("2")
          return Int(pin.numberOfImages)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.reuseIdentifier, for: indexPath) as! CollectionViewCell
        
        cell.configureCell(cell: cell, indexPath: indexPath, frc: fetchedResultsController)
        
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension LocationPhotosViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = insets.left * (itemsPerRow + 1)
        let availableWidth = self.view.bounds.width - paddingSpace
        let itemWidth = availableWidth / itemsPerRow
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return insets.left * (itemsPerRow - 2)
    }
}


//MARK: - MKMapViewDelegate
extension LocationPhotosViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "locationPhoto"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.animatesDrop = true
            pinView.canShowCallout = false
            pinView.isEnabled = false
            
            annotationView = pinView
        }
        
        return annotationView
    }
}


//MARK: - NSFetchedResultsControllerDelegate
extension LocationPhotosViewController : NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertIndexPaths = [IndexPath]()
        deleteIndexPaths = [IndexPath]()
        updateIndexPaths = [IndexPath]()
        
        if pin.hasReturned{
            pin.hasReturned = false
        }
        
        print("*** Controller will change Content")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            print("* INSERT an item at :\(newIndexPath!)")
            insertIndexPaths.append(newIndexPath!)
        case .delete:
            print("* Delete an item at :\(indexPath!)")
            deleteIndexPaths.append(indexPath!)
        case .update:
            print("* Update an item at :\(indexPath!)")
            updateIndexPaths.append(indexPath!)
        case .move:
            print("* Move an item at :\(indexPath!)")
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({
            
            for indexPath in insertIndexPaths{
                print("** Insert at :\(indexPath)")
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            for indexPath in deleteIndexPaths{
                print("** Delete at: \(indexPath)")
                self.unselectCollectionViewCells(at: indexPath)
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in updateIndexPaths{
                print("** Update at :\(indexPath)")
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: {(_) in
            self.checkForEditedPin(if: false)
            
        })
    }
    
}

//MARK: - ExecuteSearch() FetchedResultsController
extension LocationPhotosViewController {
    
    func executeSearch(){
        if let frc = fetchedResultsController{
            do{
                try frc.performFetch()
            }catch{
                print("Error while trying to perform search: \(error.localizedDescription)")
            }
        }
    }
}













