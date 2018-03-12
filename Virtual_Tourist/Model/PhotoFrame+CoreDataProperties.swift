//
//  PhotoFrame+CoreDataProperties.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/11/18.
//  Copyright © 2018 scythe. All rights reserved.
//
//

import Foundation
import CoreData


extension PhotoFrame {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoFrame> {
        return NSFetchRequest<PhotoFrame>(entityName: "PhotoFrame")
    }

    @NSManaged public var creationDate: Date
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin

}
