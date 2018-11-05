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
    
    @IBOutlet weak var syncWithIcloud: UISwitch!
    @IBOutlet weak var scanForNewFiles: UISwitch!
    
    @IBAction func performClean(_ sender: Any) {
        dataManager.cleanOutEmptyDatabases()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        syncWithIcloud.setOn(sync, animated: false)
        scanForNewFiles.setOn(scan, animated: false)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationCenter.default.post(name: Notification.Name.settingsCollectionView, object: self)
    }
    
    

}
