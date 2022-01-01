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
    static let bulletinList = Notification.Name(rawValue: "bulletinList")
    static let closingPDF = Notification.Name(rawValue: "closingPDF")
    static let closingInvoiceVC = Notification.Name(rawValue: "closingInvoiceVC")
    static let closingNotes = Notification.Name(rawValue: "closingNotes")
    static let settingsTextAnnotiations = Notification.Name(rawValue: "settingsTextAnnotiations")
    static let icloudFinished = Notification.Name(rawValue: "icloudFinished")
    static let reload = Notification.Name(rawValue: "reload")
    static let notifactionExit = Notification.Name(rawValue: "notifactionExit")
    static let postNotification = Notification.Name(rawValue: "postNotification")
    static let updateView = Notification.Name(rawValue: "updateView")
    static let blankPDFfinished = Notification.Name(rawValue: "blankPDFfinished")
    static let saveFinished = Notification.Name(rawValue: "saveFinished")
    static let applicantNotesClosing = Notification.Name(rawValue: "applicantNotesClosing")
    static let openPDFAtBookmark = Notification.Name(rawValue: "openPDFAtBookmark")
    static let openPDFAtBookmarkPDFView = Notification.Name(rawValue: "openPDFAtBookmarkPDFView")
    static let saveAndUpdateMemos = Notification.Name(rawValue: "saveAndUpdateMemos")
    static let syncCompleted = Notification.Name(rawValue: "syncCompleted")
    static let textViewDidChange = Notification.Name(rawValue: "textViewDidChange")
    static let uploadProgress = Notification.Name(rawValue: "uploadProgress")
    static let updateScanProgress = Notification.Name(rawValue: "updateScanProgress")
    static let scrollToMemo = Notification.Name(rawValue: "scrollToMemo")
    static let readingFilesFinished = Notification.Name(rawValue: "readingFilesFinished")
    static let settingsScore = Notification.Name(rawValue: "settingsScore")
    static let updateExam = Notification.Name(rawValue: "updateExam")
    static let scoreList = Notification.Name(rawValue: "scoreList")
    static let createdExam = Notification.Name(rawValue: "createdExam")
    
//    static let allArticles = Notification.Name(rawValue: "All articles")
    //    static let updateArticle = Notification.Name(rawValue: "updateArticle")
}
