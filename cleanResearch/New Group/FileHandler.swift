//
//  FileHandler.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-10-24.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import Foundation
import UIKit
import PDFKit

struct FileHandler {
    
    private let fileManagerDefault = FileManager.default
    
    func getFilenameFromURL(icloudURL: URL) -> String {
        var filename = String()
        if icloudURL.lastPathComponent.range(of:".icloud") != nil {
            filename = icloudURL.deletingPathExtension().lastPathComponent
            filename.remove(at: filename.startIndex)
        } else {
            filename = icloudURL.lastPathComponent
        }
        return filename
    }
    
    func getSize(url: URL) -> String {
        var fileSize: UInt64 = 0
        var sizeString: String = "134 kb"
        
        do {
            let attr = try fileManagerDefault.attributesOfItem(atPath: url.path)
            fileSize = attr[FileAttributeKey.size] as! UInt64
            
        } catch {
            print("Error: \(error)")
        }
        
        if fileSize < 1000 {
            sizeString = "\(fileSize)" + " b"
        } else if fileSize >= 1000 && fileSize < 1000000 {
            sizeString = "\(fileSize/1000)" + " kb"
        } else if fileSize >= 1000000 && fileSize < 1000000000 {
            let tmp = (Double(fileSize)/100000).rounded()/10
            sizeString = "\(tmp)" + " Mb"
        } else if fileSize >= 1000000000 {
            let tmp = (Double(fileSize)/100000000).rounded()/10
            sizeString = "\(tmp)" + " Gb"
        }
        
        return sizeString
    }

    func getThumbnail(icloudURL: URL, localURL: URL, localExist: Bool, pageNumber: Int) -> UIImage {
        var pageThumbnail = #imageLiteral(resourceName: "FileOffline")
        
        var url = icloudURL
        if localExist {
            url = localURL
        }
        
        if url.lastPathComponent.range(of:".jpg") != nil {
            pageThumbnail = #imageLiteral(resourceName: "JpgIcon")
            if url.lastPathComponent.range(of:".icloud") == nil {
                if let data = try? Data(contentsOf: url) {
                    pageThumbnail = UIImage(data: data)!
                }
            }
            
        } else if url.lastPathComponent.range(of:".pdf") != nil || url.lastPathComponent.range(of:".PDF") != nil {
            if let document = PDFDocument(url: url) {
                let page: PDFPage!
                page = document.page(at: pageNumber)!
                pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
            }
        } else if url.lastPathComponent.range(of:".tiff") != nil {
            pageThumbnail = #imageLiteral(resourceName: "TIFF")
            if url.lastPathComponent.range(of:".icloud") == nil {
                if let data = try? Data(contentsOf: url) {
                    pageThumbnail = UIImage(data: data)!
                }
            }
        } else if url.lastPathComponent.range(of:".png") != nil {
            pageThumbnail = #imageLiteral(resourceName: "PNG")
            if url.lastPathComponent.range(of:".icloud") == nil {
                if let data = try? Data(contentsOf: url) {
                    pageThumbnail = UIImage(data: data)!
                }
            }
        } else if url.lastPathComponent.range(of:".m") != nil {
            pageThumbnail = #imageLiteral(resourceName: "M")
        } else if url.lastPathComponent.range(of:".ai") != nil {
            pageThumbnail = #imageLiteral(resourceName: "AI")
        } else if url.lastPathComponent.range(of:".eps") != nil {
            pageThumbnail = #imageLiteral(resourceName: "EPS")
        } else if url.lastPathComponent.range(of:".pptx") != nil || url.lastPathComponent.range(of:".ppt") != nil {
            pageThumbnail = #imageLiteral(resourceName: "PowerpointIcon")
        } else if url.lastPathComponent.range(of:".docx") != nil || url.lastPathComponent.range(of:".doc") != nil {
            pageThumbnail = #imageLiteral(resourceName: "WordIcon")
        } else if url.lastPathComponent.range(of:".xlsx") != nil || url.lastPathComponent.range(of:".xlsm") != nil {
            pageThumbnail = #imageLiteral(resourceName: "ExcelIcon")
        } else if url.lastPathComponent.range(of:".key") != nil {
            pageThumbnail = #imageLiteral(resourceName: "KeynoteIcon")
        } else if url.lastPathComponent.range(of:".txt") != nil {
            pageThumbnail = #imageLiteral(resourceName: "TXT")
        }
        return pageThumbnail
        
    }
    
}