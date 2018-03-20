//
//  NotificationName.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/12/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    static let pinNumberOfImages = Notification.Name("pinNumberOfImages")
    static let errorMessageToAlertController = Notification.Name("errorMessageToAlertController")
    static let enableLoadMorePictures = Notification.Name("enableLoadMorePictures")
    static let allowCellSelection = Notification.Name("allowCellSelection")
    static let pinForGetPhotos = Notification.Name("pinForGetPhotos")
    static let removeUnfinishedPinFromAppDelegate = Notification.Name("removePinFromAppDelegate")
    static let addUnfinishedPinToAppDelegate = Notification.Name("unfinishedPinToAppDelegate")
    static let errorFinishingTheDownloadingPhotos = Notification.Name("errorFinishingTheDownloadingPhotos")
    static let enableCellsAndLoadMorePicturesButton = Notification.Name("enableCellsAndLoadMorePicturesButton")
    
}
