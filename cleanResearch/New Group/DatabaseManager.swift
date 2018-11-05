//
//  LoadIcloudRecords.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-10-21.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import Foundation
import CloudKit
import UIKit
import CoreData

class DatabaseManager {
    
    var privateDatabase: CKDatabase! = nil
    var recordZone: CKRecordZone! = nil
    
    var publicationsLF: [LocalFile] = []

    var publicationsIC: [PublicationFile] = []
    var expensesIC: [ExpenseFile] = []
    var projectsIC: [ProjectFile] = []
    var bookmarksIC: [BookmarkFile] = []
    
    var publicationsCD: [Publication] = []
    var authorsCD: [Author] = []
    var journalsCD: [Journal] = []
    var publicationGroupsCD: [PublicationGroup] = []
    var projectCD: [Project] = []
    var expensesCD: [Expense] = []
    var bookmarksCD: [Bookmarks] = []

    
    var context: NSManagedObjectContext!

    init() {
    }
    
    func saveCoreData() {
        do {
            try context.save()
            print("Saved to core data")
        } catch {
            print("Could not save core data")
        }
    }
    
    func loadCoreData() {
        
        let requestPublicationGroups: NSFetchRequest<PublicationGroup> = PublicationGroup.fetchRequest()
        requestPublicationGroups.sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true)]
        do {
            publicationGroupsCD = try context.fetch(requestPublicationGroups)
        } catch {
            print("Error loading groups")
        }
        
        let requestAuthors: NSFetchRequest<Author> = Author.fetchRequest()
        requestAuthors.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            authorsCD = try context.fetch(requestAuthors)
        } catch {
            print("Error loading authors")
        }
        
        let requestJournals: NSFetchRequest<Journal> = Journal.fetchRequest()
        requestJournals.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            journalsCD = try context.fetch(requestJournals)
        } catch {
            print("Error loading journals")
        }
        
        let request: NSFetchRequest<Publication> = Publication.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            publicationsCD = try context.fetch(request)
        } catch {
            print("Error loading publications")
        }
        
        let requestProjects: NSFetchRequest<Project> = Project.fetchRequest()
        requestProjects.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            projectCD = try context.fetch(requestProjects)
        } catch {
            print("Error loading project")
        }
        
        let requestExpenses: NSFetchRequest<Expense> = Expense.fetchRequest()
        requestExpenses.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: true)]
        do {
            expensesCD = try context.fetch(requestExpenses)
        } catch {
            print("Error loading expenses")
        }
        
        let requestBookmarks: NSFetchRequest<Bookmarks> = Bookmarks.fetchRequest()
        requestBookmarks.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            bookmarksCD = try context.fetch(requestBookmarks)
        } catch {
            print("Error loading bookmarks")
        }
    }
    
    func addFileToCoreData(file: LocalFile) {
        let newPublication = Publication(context: context)
        
        newPublication.filename = file.filename
//        newPublication.thumbnail = getThumbnail(url: publicationsURL.appendingPathComponent(file.filename), pageNumber: 0)
        newPublication.dateCreated = file.dateCreated
        newPublication.dateModified = file.dateModified
        newPublication.year = file.year!
        newPublication.note = file.note
        
        let favoriteGroup = publicationGroupsCD.first(where: {$0.tag == "Favorites"})
        if file.favorite == "Yes" {
            newPublication.favorite = "Yes"
            newPublication.addToPublicationGroup(favoriteGroup!)
        } else {
            newPublication.favorite = "No"
            newPublication.removeFromPublicationGroup(favoriteGroup!)
        }
        
        if authorsCD.first(where: {$0.name == file.author}) == nil {
            let newAuthor = Author(context: context)
            newAuthor.name = file.author
            newAuthor.sortNumber = "1"
            newPublication.author = newAuthor
        } else {
            newPublication.author = authorsCD.first(where: {$0.name == file.author})
        }
        
        if journalsCD.first(where: {$0.name == file.journal}) == nil {
            let newJournal = Journal(context: context)
            newJournal.name = file.journal
            newJournal.sortNumber = "1"
            newPublication.journal = newJournal
        } else {
            newPublication.journal = journalsCD.first(where: {$0.name == file.journal})
        }
        
        for group in file.groups {
            if let tmp = publicationGroupsCD.first(where: {$0.tag == group}) {
                newPublication.addToPublicationGroup(tmp)
            } else {
                let newGroup = PublicationGroup(context: context)
                newGroup.tag = group
                newGroup.dateModified = Date()
                newGroup.sortNumber = "3"
                newPublication.addToPublicationGroup(newGroup)
            }
        }
        
        publicationsCD.append(newPublication)
        
        saveCoreData()
        
        print("Saved " + newPublication.filename! + " to core data.")
        
    }
    
    func initIcloudLoad(database: CKDatabase, zone: CKRecordZone) {
        
        // GET PUBLICATIONS
        let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: zone.zoneID) { (records, error) in
            guard let records = records else {return}
            DispatchQueue.main.async {
                for record in records {
                    let newPublication = PublicationFile(filename: record.object(forKey: "Filename") as! String, title: record.object(forKey: "Title") as? String, year: record.object(forKey: "Year") as? Int16, thumbnails: nil, category: "Publications", rank: record.object(forKey: "Rank") as? Float, note: record.object(forKey: "Note") as? String, dateCreated: record.creationDate, dateModified: record.modificationDate, favorite: record.object(forKey: "Favorite") as? String, author: record.object(forKey: "Author") as? String, journal: record.object(forKey: "Journal") as? String, groups: record.object(forKey: "Group") as! [String?])
                    self.publicationsIC.append(newPublication)
                }
            }
        }
        
        // GET PROJECTS
        let queryProjects = CKQuery(recordType: "Projects", predicate: NSPredicate(value: true))
        database.perform(queryProjects, inZoneWith: zone.zoneID) { (records, error) in
            guard let records = records else {return}
            DispatchQueue.main.async {
                for record in records {
                    let newProject = ProjectFile(name: record.object(forKey: "Name") as! String, amountReceived: record.object(forKey: "AmountReceived") as! Int32, amountRemaining: record.object(forKey: "AmountRemaining") as! Int32, expenses: [])
                    self.projectsIC.append(newProject)
                }
            }
        }
        
        // GET EXPENSES
        let queryExpenses = CKQuery(recordType: "Expenses", predicate: NSPredicate(value: true))
        database.perform(queryExpenses, inZoneWith: zone.zoneID) { (records, error) in
            guard let records = records else {return}
            DispatchQueue.main.async {
                for record in records {
                    let newExpense = ExpenseFile(amount: record.object(forKey: "Amount") as! Int32, reference: record.object(forKey: "Reference") as? String, overhead: record.object(forKey: "Overhead") as? Int16, comment: record.object(forKey: "Comment") as? String, pdfURL: nil, localFile: nil, belongsToProject: record.object(forKey: "BelongsToProject") as! String)
                    self.expensesIC.append(newExpense)
                }
            }
        }
        
        // GET BOOKMARKS FIX
        let queryBookmarks = CKQuery(recordType: "Bookmarks", predicate: NSPredicate(value: true))
        database.perform(queryBookmarks, inZoneWith: zone.zoneID) { (records, error) in
            guard let records = records else {return}
            DispatchQueue.main.async {
                for record in records {
                    let newBookmark = BookmarkFile(filename: (record.object(forKey: "filename") as? String)!, path: (record.object(forKey: "path") as? String)!, category: (record.object(forKey: "category") as? String)!, lastPageVisited: record.object(forKey: "lastPageVisited") as? Int32, page: record.object(forKey: "page") as? [Int])
                    self.bookmarksIC.append(newBookmark)
                }
            }
        }
        NotificationCenter.default.post(name: Notification.Name.icloudFinished, object: nil)

    }
    
    func compareCDwithIC(type: String) {
        if type == "Publication" {
            for i in 0..<publicationsLF.count {
                var icloudFile: PublicationFile?
                var coreDataFile: Publication?
                var icloudFound = false
                var coreDataFound = false
                
                //SEARCH ICLOUD
                if let matchedIcloudFile = publicationsIC.first(where: {$0.filename == publicationsLF[i].filename}) {
                    icloudFile = matchedIcloudFile
                    icloudFound = true
                }
                
                //SEARCH ICLOUD
                if let matchedIcloudFile = publicationsCD.first(where: {$0.filename == publicationsLF[i].filename}) {
                    coreDataFile = matchedIcloudFile
                    coreDataFound = true
                }
                
                if icloudFound && coreDataFound {
                    if coreDataFile!.dateModified! > icloudFile!.dateModified! {
//                        updateLocalFileWithCoreData(index: i, currentFile: coreDataFile!)
                    } else {
                        print(icloudFile)
//                        updateLocalFileWithIcloud(index: i, currentFile: icloudFile!)
                    }
                } else {
                    if icloudFound || coreDataFound {
                        if icloudFound {
//                            updateLocalFileWithIcloud(index: i, currentFile: icloudFile!)
                        } else {
//                            updateLocalFileWithCoreData(index: i, currentFile: coreDataFile!)
                        }
                    } else {
                        //                        addFileToCoreData(file: localFiles[0][i])
                    }
                }
                
                
            }
        }
    }
    
    func setupDefaultCoreDataTypes() {
        
        // ADD "NO AUTHOR"
        let arrayAuthors = authorsCD
        if arrayAuthors.first(where: {$0.name == "No author"}) == nil {
            let newAuthor = Author(context: context)
            newAuthor.name = "No author"
            newAuthor.sortNumber = "0"
        }
        
        // ADD "NO JOURNAL"
        let arrayJournals = journalsCD
        if arrayJournals.first(where: {$0.name == "No journal"}) == nil {
            let newJournal = Journal(context: context)
            newJournal.name = "No journal"
            newJournal.sortNumber = "0"
        }
        
        // ADD "ALL PUBLICATIONS"
        let arrayPublicationGroups = publicationGroupsCD
        if arrayPublicationGroups.first(where: {$0.tag == "All publications"}) == nil {
            let newPublicationGroup = PublicationGroup(context: context)
            newPublicationGroup.tag = "All publications"
            newPublicationGroup.dateModified = Date()
            newPublicationGroup.sortNumber = "0"
        }
        
        // ADD "FAVORITES"
        if publicationGroupsCD.first(where: {$0.tag == "Favorites"}) == nil {
            let favoriteGroup = PublicationGroup(context: context)
            favoriteGroup.tag = "Favorites"
            favoriteGroup.dateModified = Date()
            favoriteGroup.sortNumber = "1"
        }
        
        saveCoreData()
//        loadCoreData()
    }
    
    func updateCoreData(file: LocalFile, oldFilename: String?, newFilename: String?) {
        
        var filename = file.filename
        if oldFilename != nil {
            filename = oldFilename!
        }
        
        if let currentPublication = publicationsCD.first(where: {$0.filename == filename}) {
            
            if oldFilename != nil {
                currentPublication.filename = newFilename!
            } else {
                currentPublication.filename = filename
            }
            
            currentPublication.dateModified = Date()
            currentPublication.rank = file.rank!
            currentPublication.year = file.year!
            currentPublication.note = file.note
            
            if authorsCD.first(where: {$0.name == file.author}) == nil {
                let newAuthor = Author(context: context)
                newAuthor.name = file.author
                newAuthor.sortNumber = "1"
                print("Added new author: " + newAuthor.name!)
                currentPublication.author = newAuthor
            } else {
                currentPublication.author = authorsCD.first(where: {$0.name == file.author})
            }
            
            if journalsCD.first(where: {$0.name == file.journal}) == nil {
                let newJournal = Journal(context: context)
                newJournal.name = file.journal
                newJournal.sortNumber = "1"
                print("Added new journal: " + newJournal.name!)
                currentPublication.journal = newJournal
            } else {
                currentPublication.journal = journalsCD.first(where: {$0.name == file.journal})
                print("Added to journal: " + (currentPublication.journal?.name)!)
            }
            
            for group in file.groups {
                if let tmp = publicationGroupsCD.first(where: {$0.tag == group}) {
                    currentPublication.addToPublicationGroup(tmp) //Assume (for now) that all groups can be found in publicationGroupsCD
                } else {
                    let newGroup = PublicationGroup(context: context)
                    newGroup.tag = group
                    newGroup.sortNumber = "3"
                    newGroup.dateModified = Date()
                    print("Added new group: " + newGroup.tag!)
                    currentPublication.addToPublicationGroup(newGroup)
                }
            }
            
            saveCoreData()
//            loadCoreData()
            
        } else {
            // A FILE FOUND IN FOLDER BUT NOT SAVED INTO CORE DATA
            addFileToCoreData(file: file)
        }
    }
    
//    var publicationsCD: ([Publication], [Author], [Journal], [PublicationGroup], [Expense], [Project], [Bookmarks]) {
//        get {
//            return (publicationsCD, authorsCD, journalsCD, publicationGroupsCD, expensesCD, projectCD, bookmarksCD)
//        }
//    }

}
