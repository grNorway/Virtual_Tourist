//
//  AppDelegate.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/11/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let coreDataStack = CoreDataStack(modelName: "Model")!
    var unfinishedPins = [Pin]()
    private enum addRemoveObservers {
        case added , removed
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        passCoreDataStack()
        observersForUnfinishedPins(are: .added)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveHasReturnedPinsOnExit(are: true)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        saveHasReturnedPinsOnExit(are: false)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        observersForUnfinishedPins(are: .removed)
        saveHasReturnedPinsOnExit(are: true)
    }
    
    
    

    // Send stack to MapViewController
    private func passCoreDataStack(){
        let navigationController = window!.rootViewController as! UINavigationController
        let mapViewController = navigationController.viewControllers.first as! MapViewController
        mapViewController.stack = coreDataStack
    }
    
    // Add/Remove Observers for unfinished Pins
    private func observersForUnfinishedPins(are observersAre:addRemoveObservers){
        switch observersAre{
        case .added:
            NotificationCenter.default.addObserver(self, selector: #selector(addUnfinishedPin(_:)), name: .addUnfinishedPinToAppDelegate, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(removeUnfinishedPin(_:)), name: .removeUnfinishedPinFromAppDelegate, object: nil)
        case .removed:
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // Add unfinishedPin to Array
    @objc private func addUnfinishedPin(_ notification:Notification){
        
        guard let unfinishedPin = notification.userInfo?["unfinishedPin"] as? Pin else {return}
        self.unfinishedPins.append(unfinishedPin)
        print("Unfinished Pin added to appDelegate")
    }
    
    // Remove unfinishedPin from Array
    @objc private func removeUnfinishedPin(_ notification:Notification){
        
        guard let unfinishedPin = notification.userInfo?["unfinishedPin"] as? Pin else {return}
        
        for pin in unfinishedPins{
            if pin == unfinishedPin{
                if let index = unfinishedPins.index(of: pin){
                    self.unfinishedPins.remove(at: index)
                    print("Unfinished Pin has removed from appDelegate")
                }
            }
        }
    }
    
    // Sets the hasReturned property according the exit of the App
    // If the get method has not returned from the API for varius reasons
    private func saveHasReturnedPinsOnExit(are saved:Bool){
        for pin in unfinishedPins{
            coreDataStack.mainContext.performAndWait {
                switch saved{
                case true:
                    pin.hasReturned = true
                case false:
                    pin.hasReturned = false
                }
            }
        }
        coreDataStack.saveChanges()
    }
    
    

}

