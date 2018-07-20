//
//  settingsViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-07-03.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    var currentTheme: Int!

    @IBOutlet weak var syncWithIcloud: UISwitch!
    @IBOutlet weak var blueThemeButton: UIButton!
    @IBOutlet weak var redThemeButton: UIButton!
    @IBOutlet weak var blackThemeButton: UIButton!
    
    @IBAction func blueThemeTapped(_ sender: Any) {
        currentTheme = 0
        blueThemeButton.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        blueThemeButton.borderWidth = 5
        redThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        redThemeButton.borderWidth = 2
        blackThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        blackThemeButton.borderWidth = 2
    }
    
    @IBAction func redThemeTapped(_ sender: Any) {
        currentTheme = 1
        blueThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        blueThemeButton.borderWidth = 2
        redThemeButton.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        redThemeButton.borderWidth = 5
        blackThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        blackThemeButton.borderWidth = 2
    }
    
    @IBAction func blackThemeTapped(_ sender: Any) {
        currentTheme = 2
        blueThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        blueThemeButton.borderWidth = 2
        redThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        redThemeButton.borderWidth = 2
        blackThemeButton.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        blackThemeButton.borderWidth = 5
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDefaultTheme(currentTheme: currentTheme)

        // Do any additional setup after loading the view.
    }

    func setDefaultTheme(currentTheme: Int) {
        switch currentTheme {
        case 0:
            blueThemeButton.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            blueThemeButton.borderWidth = 5
            redThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            redThemeButton.borderWidth = 2
            blackThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            blackThemeButton.borderWidth = 2
        case 1:
            blueThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            blueThemeButton.borderWidth = 2
            redThemeButton.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            redThemeButton.borderWidth = 5
            blackThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            blackThemeButton.borderWidth = 2
        case 2:
            blueThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            blueThemeButton.borderWidth = 2
            redThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            redThemeButton.borderWidth = 2
            blackThemeButton.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            blackThemeButton.borderWidth = 5
        default:
            blueThemeButton.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            blueThemeButton.borderWidth = 5
            redThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            redThemeButton.borderWidth = 2
            blackThemeButton.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            blackThemeButton.borderWidth = 2
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.settingsCollectionView, object: self)
    }
    
    

}
