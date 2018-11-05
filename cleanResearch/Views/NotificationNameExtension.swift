//
//  NotificationNameExtension.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-09.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import Foundation

extension Notification.Name {
    //    static let addNewResearchItem = Notification.Name(rawValue: "addResearchItem")
//    static let addNewArticle = Notification.Name(rawValue: "addNewArticle")
    static let sendPDFfilename = Notification.Name(rawValue: "sendPDFfilename")
    static let sortSubtable = Notification.Name(rawValue: "sortSubtable")
    static let sortCollectionView = Notification.Name(rawValue: "sortCollectionView")
    static let settingsCollectionView = Notification.Name(rawValue: "settingsCollectionView")
    static let settingsHighlighter = Notification.Name(rawValue: "settingsHighlighter")
    static let textViewDidChange = Notification.Name(rawValue: "textViewDidChange")
    static let closingPDF = Notification.Name(rawValue: "closingPDF")
    static let closingInvoiceVC = Notification.Name(rawValue: "closingInvoiceVC")
    static let closingNotes = Notification.Name(rawValue: "closingNotes")
    static let settingsTextAnnotiations = Notification.Name(rawValue: "settingsTextAnnotiations")
    static let icloudFinished = Notification.Name(rawValue: "icloudFinished")
    static let reload = Notification.Name(rawValue: "reload")
    
//    static let allArticles = Notification.Name(rawValue: "All articles")
    //    static let updateArticle = Notification.Name(rawValue: "updateArticle")
}
