//
//  HiringNotesViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2019-01-26.
//  Copyright © 2019 Elias Kristensson. All rights reserved.
//

import UIKit

class HiringNotesViewController: UIViewController {

    var text: String!
    
    @IBOutlet weak var notes: UITextView!
    
    @IBAction func tappedOutside(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notes.layer.borderColor = UIColor.lightGray.cgColor
        notes.layer.borderWidth = 1
        notes.layer.cornerRadius = 8
        notes.text = text
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.applicantNotesClosing, object: self)
    }
    
}
