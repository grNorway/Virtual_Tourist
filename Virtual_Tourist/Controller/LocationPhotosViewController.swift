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
    
    
    
    //MARK: - Core Data Properties
    var pin : Pin!
    var stack : CoreDataStack!
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    
    //MARK: - Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print(pin)
        
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}

extension LocationPhotosViewController: UICollectionViewDelegate {
    
}

extension LocationPhotosViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}
