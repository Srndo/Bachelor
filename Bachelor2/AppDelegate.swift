//
//  AppDelegate.swift
//  Bachelor2
//
//  Created by Simon Sestak on 18/03/2021.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let fileManager = FileManager.default
        
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docURL = documentsDirectory else { printError(from: "appStart", message: "Documents directory is nil"); return false }
        let imagesPath = docURL.appendingPathComponent("Images")
        let documentsPath = docURL.appendingPathComponent("Documents")
        
        if !fileManager.fileExists(atPath: imagesPath.path) {
            do {
                try fileManager.createDirectory(atPath: imagesPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error);
                return false
            }
        }
        
        if !fileManager.fileExists(atPath: documentsPath.path) {
            do {
                try fileManager.createDirectory(atPath: documentsPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error);
                return false
            }
        }
        
        let zoneSet: Bool = UserDefaults.standard.bool(forKey: "ZoneSet")
        
        if !zoneSet {
            let myRecordZone = CKRecordZone(zoneName: "Bachelor")
            let container = CKContainer(identifier: "iCloud.cz.vutbr.fit.xsesta06")
            container.privateCloudDatabase.save(myRecordZone, completionHandler:
            ({returnRecord, error in
                if let err = error {
                    print(err.localizedDescription)
                    UserDefaults.standard.set(false, forKey: "ZoneSet")
                } else {
                    print("Zone created")
                    UserDefaults.standard.set(true, forKey: "ZoneSet")
                }
            }))
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Bachelor2")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

