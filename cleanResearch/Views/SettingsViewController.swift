//
//  settingsViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-07-03.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    var sync: Bool!
    var scan: Bool!
    var dataManager: DataManager!
    var recentDays: Int!
    
    @IBOutlet weak var syncWithIcloud: UISwitch!
    @IBOutlet weak var scanForNewFiles: UISwitch!
    @IBOutlet weak var recentDaysStepper: UIStepper!
    @IBOutlet weak var recentDaysText: UILabel!
    
    @IBAction func performClean(_ sender: Any) {
        dataManager.cleanOutEmptyDatabases()
    }
    
    @IBAction func recentDaysChanged(_ sender: Any) {
        recentDays = Int(recentDaysStepper.value)
        recentDaysText.text = "\(recentDays!)" + " days in Recent"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        syncWithIcloud.setOn(sync, animated: false)
        scanForNewFiles.setOn(scan, animated: false)
        recentDaysStepper.value = Double(recentDays)
        recentDaysText.text = "\(recentDays!)" + " days in Recent"
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.settingsCollectionView, object: self)
    }
    
    

}
