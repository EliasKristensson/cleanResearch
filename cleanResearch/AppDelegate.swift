//
//  AppDelegate.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-04.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!

    var iCloudAvailable: Bool!
    var window: UIWindow?
    var iCloudURL: URL?
    var docURL: URL?
    var localURL: URL?
    var publicationURL: URL?
    var booksURL: URL?
    var economyURL: URL?
    var manuscriptURL: URL?
    var presentationURL: URL?
    var proposalsURL: URL?
    var supervisionURL: URL?
    var teachingURL: URL?
    var patentsURL: URL?
    var coursesURL: URL?
    var meetingsURL: URL?
    var conferencesURL: URL?
    var reviewsURL: URL?
    var workDocsURL: URL?
    var hiringURL: URL?
    var travelURL: URL?
    var notesURL: URL?
    var miscellaneousURL: URL?
    var docsDir: URL?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        CKContainer.default().accountStatus{ status, error in
            guard status == .available else {
                print("Icloud is not available")
                self.iCloudAvailable = false
                return
            }
            print("Icloud is available")
            self.iCloudAvailable = true
        }
        
        localURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        docURL = iCloudURL?.appendingPathComponent("Documents", isDirectory: true)
        
        let tmp = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        docsDir = tmp[0]
        
        publicationURL = docURL?.appendingPathComponent("Publications", isDirectory: true)
        booksURL = docURL?.appendingPathComponent("Books", isDirectory: true)
        economyURL = docURL?.appendingPathComponent("Economy", isDirectory: true)
        manuscriptURL = docURL?.appendingPathComponent("Manuscripts", isDirectory: true)
        presentationURL = docURL?.appendingPathComponent("Presentations", isDirectory: true)
        proposalsURL = docURL?.appendingPathComponent("Proposals", isDirectory: true)
        supervisionURL = docURL?.appendingPathComponent("Supervision", isDirectory: true)
        teachingURL = docURL?.appendingPathComponent("Teaching", isDirectory: true)
        patentsURL = docURL?.appendingPathComponent("Patents", isDirectory: true)
        coursesURL = docURL?.appendingPathComponent("Courses", isDirectory: true)
        meetingsURL = docURL?.appendingPathComponent("Meetings", isDirectory: true)
        conferencesURL = docURL?.appendingPathComponent("Conferences", isDirectory: true)
        reviewsURL = docURL?.appendingPathComponent("Reviews", isDirectory: true)
        workDocsURL = docURL?.appendingPathComponent("Work documents", isDirectory: true)
        hiringURL = workDocsURL?.appendingPathComponent("Hiring", isDirectory: true)
        travelURL = docURL?.appendingPathComponent("Travel", isDirectory: true)
        notesURL = docURL?.appendingPathComponent("Notes", isDirectory: true)
        miscellaneousURL = docURL?.appendingPathComponent("Miscellaneous", isDirectory: true)
        
        if iCloudURL != nil {
            // Create folders under iCloud Drive/cleanResearch/...
            do {
                try FileManager.default.createDirectory(at: publicationURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: booksURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: economyURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: manuscriptURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: presentationURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: proposalsURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: supervisionURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: teachingURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: patentsURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: coursesURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: meetingsURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: conferencesURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: reviewsURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: workDocsURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: hiringURL!, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: travelURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: notesURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            do {
                try FileManager.default.createDirectory(at: miscellaneousURL!, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        } else {
            print("iCloud nil")
        }
        
        // Core data
        container = NSPersistentContainer(name: "cleanResearch")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if error == nil {
                self.context = self.container.viewContext
            } else {
                print("Error loading persistent store")
            }
        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "cleanResearch")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
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
