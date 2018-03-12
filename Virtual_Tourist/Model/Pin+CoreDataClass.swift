//
//  Pin+CoreDataClass.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/11/18.
//  Copyright © 2018 scythe. All rights reserved.
//
//

import Foundation
import CoreData


public class Pin: NSManagedObject {

    convenience init(latitude: Double , longitude : Double , context : NSManagedObjectContext){
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context){
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
            self.creationDate = Date()
            self.hasReturned = true
            self.numberOfImages = 0
        }else{
            fatalError("Unable to Find Entity name 'Pin'")
        }
    }
    
    var dateFormatter : String {
        get{
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            formatter.doesRelativeDateFormatting = true
            formatter.locale = Locale.current
            return formatter.string(from: creationDate)
        }
    }
}
