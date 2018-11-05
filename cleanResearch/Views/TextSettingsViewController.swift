//
//  TextSettingsViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-10-11.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class TextSettingsViewController: UIViewController {

    var remove = false
    var move = false
    var fontSize: Int!
    var selectedSettings: [Int]!
    
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var fontSizeButtons: UIStepper!
    @IBOutlet weak var moveButton: UIButton!
    
    @IBAction func moveButtonTapped(_ sender: Any) {
        move = true
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func changeFontSize(_ sender: Any) {
        fontSize = Int(fontSizeButtons.value)
        selectedSettings[6] = fontSize
        fontSizeLabel.text = "Font size: " + "\(selectedSettings[6])" + " pt"
    }

    @IBAction func removeTextTapped(_ sender: Any) {
        remove = true
        dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if selectedSettings[6] < 5 {
            selectedSettings[6] = 5
        }
        fontSize = selectedSettings[6]
        fontSizeLabel.text = "Font size: " + "\(selectedSettings[6])" + " pt"

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.settingsTextAnnotiations, object: self)
    }

}
