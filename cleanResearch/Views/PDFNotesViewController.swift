//
//  PDFNotesViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2020-12-30.
//  Copyright © 2020 Elias Kristensson. All rights reserved.
//

import UIKit

class PDFNotesViewController: UIViewController {

    var note: String?
    var filename: String?
    
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBAction func tappedOutside(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if note != nil {
            notesTextView.text = note
        } else {
            notesTextView.text = ""
        }
        
        titleLabel.text = "Notes"
        if filename != nil {
            titleLabel.text = "Notes: " + filename!
        }
        
        notesTextView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        notesTextView.layer.borderWidth = 2
        notesTextView.layer.cornerRadius = 10

    }
    

}
