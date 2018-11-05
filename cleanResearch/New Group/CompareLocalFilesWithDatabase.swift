//
//  compareLocalFilesWithDatabase.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-10-21.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import Foundation
import UIKit

struct CompareDatabases {
    
//    var category: String
    var publicationsIC: [PublicationFile] = []
    var publicationsCD: [Publication] = []
    var publicationsLF: [LocalFile] = []
//    private var publicationsReturned: [[LocalFile]] = [[]]
    
    mutating func compareCDwithIC(type: String) {
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
                        updateLocalFileWithCoreData(index: i, currentFile: coreDataFile!)
                    } else {
                        print(icloudFile)
                        updateLocalFileWithIcloud(index: i, currentFile: icloudFile!)
                    }
                } else {
                    if icloudFound || coreDataFound {
                        if icloudFound {
                            updateLocalFileWithIcloud(index: i, currentFile: icloudFile!)
                        } else {
                            updateLocalFileWithCoreData(index: i, currentFile: coreDataFile!)
                        }
                    } else {
//                        addFileToCoreData(file: localFiles[0][i])
                    }
                }
                
                
            }
        }
    }
    
    mutating func updateLocalFileWithIcloud(index: Int, currentFile: PublicationFile) {
        publicationsLF[index].year = currentFile.year
        publicationsLF[index].rank = currentFile.rank
        publicationsLF[index].note = currentFile.note!
        publicationsLF[index].dateCreated = currentFile.dateCreated!
        publicationsLF[index].dateModified = currentFile.dateModified!
        publicationsLF[index].favorite = currentFile.favorite!
        
        if currentFile.author != nil {
            publicationsLF[index].author = currentFile.author!
//            if authorsCD.first(where: {$0.name == currentFile.author}) == nil {
//                let newAuthor = Author(context: context)
//                newAuthor.name = currentFile.author
//                newAuthor.sortNumber = "1"
//                print("Added new author: " + newAuthor.name!)
//                saveCoreData()
//                loadCoreData()
//            }
        } else {
            publicationsLF[index].author = "No author"
        }
        
        
        if currentFile.journal != nil {
            publicationsLF[index].journal = currentFile.journal!
//            if journalsCD.first(where: {$0.name == currentFile.journal}) == nil {
//                let newJournal = Journal(context: context)
//                newJournal.name = currentFile.journal
//                newJournal.sortNumber = "1"
//                print("Added new journal: " + newJournal.name!)
//                saveCoreData()
//                loadCoreData()
//            }
        } else {
            publicationsLF[index].journal = "No journal"
        }
        
        publicationsLF[index].groups = currentFile.groups
        print("Icloud file: " + publicationsLF[index].filename)
        
        //Update Core data with just updated localFiles
//        updateCoreData(file: localFiles[category][index], oldFilename: nil, newFilename: nil)
        
    }

    mutating func updateLocalFileWithCoreData(index: Int, currentFile: Publication) {
        
        publicationsLF[index].year = currentFile.year
        publicationsLF[index].rank = currentFile.rank
        publicationsLF[index].note = currentFile.note!
        publicationsLF[index].dateCreated = currentFile.dateCreated!
        publicationsLF[index].dateModified = currentFile.dateModified!
        
        if publicationsLF[index].thumbnail == #imageLiteral(resourceName: "fileIcon.png") {
            if let thumbnail = currentFile.thumbnail as? UIImage {
                publicationsLF[index].thumbnail = thumbnail
            }
        }
        
        if let author = currentFile.author?.name {
            publicationsLF[index].author = author
        } else {
            publicationsLF[index].author = "No author"
        }
        
        if let journal = currentFile.journal?.name {
            publicationsLF[index].journal = journal
        } else {
            publicationsLF[index].journal = "No journal"
        }
        
        publicationsLF[index].favorite = "No"
        for group in currentFile.publicationGroup?.allObjects as! [PublicationGroup] {
            publicationsLF[index].groups.append(group.tag)
            if group.tag == "Favorites" {
                publicationsLF[index].favorite = "Yes"
            }
        }
    }
    
    var comparedDatabase: [LocalFile] {
        get {
            return publicationsLF
        }
    }

    
}
