//
//  PhotoFrame+CoreDataClass.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/11/18.
//  Copyright © 2018 scythe. All rights reserved.
//
//

import Foundation
import CoreData


public class PhotoFrame: NSManagedObject {

    convenience init(pin: Pin , imageData: NSData , context : NSManagedObjectContext){
        if let ent = NSEntityDescription.entity(forEntityName: "PhotoFrame", in: context){
            self.init(entity: ent, insertInto: context)
            self.pin = pin
            self.imageData = imageData
            self.creationDate = Date()
        }else{
            fatalError("Unable To Find Entity name 'PhotoFrame'")
        }
    }
    
    var dateFormatter : String {
        get{
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .short
            dateFormatter.doesRelativeDateFormatting = true
            dateFormatter.locale = Locale.current
            return dateFormatter.string(from: creationDate)
        }
    }
}
