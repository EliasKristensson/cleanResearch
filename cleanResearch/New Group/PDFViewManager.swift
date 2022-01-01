//
//  PDFViewManager.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2019-08-22.
//  Copyright © 2019 Elias Kristensson. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData
import PDFKit



class PDFViewManager {

    // Different actions
    enum actionType {
        case pen
        case highlight
        case moveAnnotation
        case moveRuler
        case moveText
        case selectAnnotation
        case addText
        case erase
        case save
        case none
    }

    // Different touches
    enum touchTypes {
        case active
        case inactive
    }

    // Search
    enum search {
        case on
        case off
    }
    
    var colors: [[CGFloat]] = [[255/255.0, 255/255.0, 255/255.0], [0/255.0, 0/255.0, 0/255.0], [255/255.0, 255/255.0, 0/255.0], [164/255.0, 196/255.0, 0/255.0], [96/255.0, 169/255.0, 23/255.0], [0/255.0, 138/255.0, 0/255.0], [0/255.0, 171/255.0, 169/255.0], [27/255.0, 161/255.0, 226/255.0], [0/255.0, 80/255.0, 239/255.0], [106/255.0, 0/255.0, 255/255.0], [170/255.0, 0/255.0, 255/255.0], [244/255.0, 114/255.0, 208/255.0], [216/255.0, 0/255.0, 115/255.0], [162/255.0, 0/255.0, 37/255.0], [229/255.0, 20/255.0, 0/255.0], [250/255.0, 104/255.0, 0/255.0], [240/255.0, 163/255.0, 10/255.0], [227/255.0, 200/255.0, 0/255.0], [130/255.0, 90/255.0, 44/255.0], [109/255.0, 135/255.0, 100/255.0], [100/255.0, 118/255.0, 135/255.0], [118/255.0, 96/255.0, 138/255.0], [135/255.0, 121/255.0, 78/255.0], [51/255.0, 51/255.0, 51/255.0], [102/255.0, 102/255.0, 102/255.0], [153/255.0, 153/255.0, 153/255.0], [204/255.0, 204/255.0, 204/255.0] ]
    
    var action = actionType.none
    var prevAction = actionType.pen
    var altAction = actionType.erase
    var touchState = touchTypes.inactive
    var searching = search.off
    var takeNotes = false
    var audioRecording = false
    var numberOfTouches = 1
    var changesMade = false
    var saving = false
    var notes: String? = nil
    var pdfView: PDFView!
    
    var notesDown = false
    
    //
    var dataManager: DataManager!
    
    // FILES
    var currentFile: LocalFile!
    
    // TIMERS
    var saveTimer: Timer!
    var saveTime: Int!
    var postTimer: Timer!
    
    // ANNOTATIONS VARIABLES
    var annotationsAltered: [(annotation: PDFAnnotation, action: actionType, page: PDFPage?)]? = []
    var currentAnnotation: PDFAnnotation!

    // TYPING
    let fonts = ["Arial", "Helvetica Neue", "Times New Roman"]
    let fontSizes = ["5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40"]
    let fontTypes = ["Normal", "Bold", "Italic"]
    
    // AUDIO & SPEACH
    var audio: [(language: String, code: String)] = [(language: "English - US", code: "en-US"), (language: "Enlish - UK", code: "en-GB"), (language: "German", code: "de-DE"), (language: "French", code: "fr-FR"), (language: "Swedish", code: "sv-SE"), (language: "Danish", code: "da-DK")]
    var voices: [(language: String, code: String)] = [(language: "English - US", code: "en-US"), (language: "Enlish - UK", code: "en-GB"), (language: "German", code: "de-DE"), (language: "French", code: "fr-FR"), (language: "Swedish", code: "sv-SE"), (language: "Danish", code: "da-DK")]
    
    
    // FUNCTIONS
    func getPageText() -> String {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        if let page = pdfView.document?.page(at: currentPage!-1) {
            if let pageContent = page.attributedString {
                return pageContent.string
            }
        }
        return ""
    }
    
    func handleNotesClosing(vc: NotesViewController) {
        
        if vc.update {
            let number = dataManager.categories.index(where: { $0 == currentFile?.category })
            if let index = dataManager.localFiles[number!].index(where: {$0.filename == currentFile?.filename}) {
                dataManager.localFiles[number!][index] = currentFile!
            }
            
            if vc.filenameChanged {
                print("Filename changed")
                
                dataManager.updateIcloud(file: currentFile!, oldFilename: vc.originalFilename, newFilename: currentFile?.filename, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
                dataManager.updateCoreData(file: currentFile!, oldFilename: vc.originalFilename, newFilename: currentFile?.filename)
                
            } else {
                
                dataManager.updateIcloud(file: currentFile!, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
                dataManager.updateCoreData(file: currentFile!, oldFilename: nil, newFilename: nil)
                
            }
        }
    }
    
    func setJournal(author: String) {
        if currentFile.category == "Publications" {
            currentFile.author = author
            
            let number = dataManager.categories.index(where: { $0 == currentFile?.category })
            if let index = dataManager.localFiles[number!].index(where: {$0.filename == currentFile?.filename}) {
                dataManager.localFiles[number!][index] = currentFile!
            }
            
            dataManager.updateIcloud(file: currentFile!, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
            dataManager.updateCoreData(file: currentFile!, oldFilename: nil, newFilename: nil)
        }
    }
    
    func setJournal(journal: String) {
        if currentFile.category == "Publications" {
            currentFile.journal = journal
            
            let number =  dataManager.categories.index(where: { $0 == currentFile?.category })
            if let index = dataManager.localFiles[number!].index(where: {$0.filename == currentFile?.filename}) {
                dataManager.localFiles[number!][index] = currentFile!
            }
            
            dataManager.updateIcloud(file: currentFile!, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
            dataManager.updateCoreData(file: currentFile!, oldFilename: nil, newFilename: nil)
        }
    }
    
    
}
