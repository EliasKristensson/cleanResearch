//
//  PenSettingsViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-08-13.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class PenSettingsViewController: UIViewController {

    var color: UIColor!
    var thickness: CGFloat!
    var type: String!
    var selectedSettings: [Int]!
    
    @IBOutlet weak var straightButton: UIButton!
    @IBOutlet weak var swigglyButton: UIButton!
    @IBOutlet weak var thickness10Button: UIButton!
    @IBOutlet weak var thickness15Button: UIButton!
    @IBOutlet weak var thickness20Button: UIButton!
    @IBOutlet weak var thickness25Button: UIButton!
    @IBOutlet weak var thickness30Button: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    @IBOutlet weak var grayButton: UIButton!
    
    
    @IBAction func blueHighlighter(_ sender: Any) {
        color = UIColor.blue
        unselectColors()
        blueButton.setImage(#imageLiteral(resourceName: "BlueHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 1
    }
    @IBAction func redHighlighter(_ sender: Any) {
        color = UIColor.red
        unselectColors()
        redButton.setImage(#imageLiteral(resourceName: "RedHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 2
    }
    @IBAction func greenHighlighter(_ sender: Any) {
        color = UIColor.green
        unselectColors()
        greenButton.setImage(#imageLiteral(resourceName: "RedHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 3
    }
    @IBAction func yellowHighlighter(_ sender: Any) {
        color = UIColor.yellow
        unselectColors()
        yellowButton.setImage(#imageLiteral(resourceName: "YellowHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 4
    }
    @IBAction func grayHighlighter(_ sender: Any) {
        color = UIColor.lightGray
        unselectColors()
        grayButton.setImage(#imageLiteral(resourceName: "GrayHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 5
    }
    
    
    @IBAction func thickness10(_ sender: Any) {
        thickness = 3
        unselectLine()
        thickness10Button.setImage(#imageLiteral(resourceName: "LineThickness10Selected@167"), for: .normal)
        selectedSettings[1] = 1
    }
    @IBAction func thickness15(_ sender: Any) {
        thickness = 5
        unselectLine()
        thickness15Button.setImage(#imageLiteral(resourceName: "LineThickness15Selected@167"), for: .normal)
        selectedSettings[1] = 2
    }
    @IBAction func thickness20(_ sender: Any) {
        thickness = 10
        unselectLine()
        thickness20Button.setImage(#imageLiteral(resourceName: "LineThickness20Selected@167"), for: .normal)
        selectedSettings[1] = 3
    }
    @IBAction func thickness25(_ sender: Any) {
        thickness = 12
        unselectLine()
        thickness25Button.setImage(#imageLiteral(resourceName: "LineThickness25Selected@167"), for: .normal)
        selectedSettings[1] = 4
    }
    @IBAction func thickness30(_ sender: Any) {
        thickness = 15
        unselectLine()
        thickness30Button.setImage(#imageLiteral(resourceName: "LineThickness30Selected@167"), for: .normal)
        selectedSettings[1] = 5
    }
    
    @IBAction func swigglyHighlighter(_ sender: Any) {
        type = "Swiggly"
        swigglyButton.setImage(#imageLiteral(resourceName: "HighlightSwigglySelected"), for: .normal)
        straightButton.setImage(#imageLiteral(resourceName: "HighlightStraight"), for: .normal)
        selectedSettings[2] = 2
    }
    
    @IBAction func straightHighlighter(_ sender: Any) {
        type = "Straight"
        swigglyButton.setImage(#imageLiteral(resourceName: "HighlightSwiggly"), for: .normal)
        straightButton.setImage(#imageLiteral(resourceName: "HighlightStraightSelected"), for: .normal)
        selectedSettings[2] = 1
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        unselectColors()
        unselectLine()
        
        print(selectedSettings)
        
        switch selectedSettings[0] {
        case 1:
            blueButton.setImage(#imageLiteral(resourceName: "BlueHighlighterSelected@167px"), for: .normal)
        case 2:
            redButton.setImage(#imageLiteral(resourceName: "RedHighlighterSelected@167px"), for: .normal)
        case 3:
            greenButton.setImage(#imageLiteral(resourceName: "GreenHighlighterSelected@167px"), for: .normal)
        case 4:
            yellowButton.setImage(#imageLiteral(resourceName: "YellowHighlighterSelected@167px"), for: .normal)
        case 5:
            grayButton.setImage(#imageLiteral(resourceName: "GrayHighlighterSelected@167px"), for: .normal)
        default:
            blueButton.setImage(#imageLiteral(resourceName: "BlueHighlighterSelected@167px"), for: .normal)
        }
        switch selectedSettings[1] {
        case 1:
            thickness10Button.setImage(#imageLiteral(resourceName: "LineThickness10Selected@167"), for: .normal)
        case 2:
            thickness15Button.setImage(#imageLiteral(resourceName: "LineThickness15Selected@167"), for: .normal)
        case 3:
            thickness20Button.setImage(#imageLiteral(resourceName: "LineThickness20Selected@167"), for: .normal)
        case 4:
            thickness25Button.setImage(#imageLiteral(resourceName: "LineThickness25Selected@167"), for: .normal)
        case 5:
            thickness30Button.setImage(#imageLiteral(resourceName: "LineThickness30Selected@167"), for: .normal)
        default:
            thickness10Button.setImage(#imageLiteral(resourceName: "LineThickness10Selected@167"), for: .normal)
        }
        switch selectedSettings[2] {
        case 1:
            straightButton.setImage(#imageLiteral(resourceName: "HighlightStraightSelected"), for: .normal)
            swigglyButton.setImage(#imageLiteral(resourceName: "HighlightSwiggly"), for: .normal)
        case 2:
            straightButton.setImage(#imageLiteral(resourceName: "HighlightStraight"), for: .normal)
            swigglyButton.setImage(#imageLiteral(resourceName: "HighlightSwigglySelected"), for: .normal)
        default:
            straightButton.setImage(#imageLiteral(resourceName: "HighlightStraightSelected"), for: .normal)
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.settingsHighlighter, object: self)
    }
    
    func unselectColors() {
        blueButton.setImage(#imageLiteral(resourceName: "BlueHighlighter@167px"), for: .normal)
        redButton.setImage(#imageLiteral(resourceName: "RedHighlighter@167px"), for: .normal)
        greenButton.setImage(#imageLiteral(resourceName: "GreenHighlighter@167px"), for: .normal)
        yellowButton.setImage(#imageLiteral(resourceName: "YellowHighlighter@167px"), for: .normal)
        grayButton.setImage(#imageLiteral(resourceName: "GrayHighlighter@167px"), for: .normal)
    }

    func unselectLine() {
        thickness10Button.setImage(#imageLiteral(resourceName: "LineThickness10@167"), for: .normal)
        thickness15Button.setImage(#imageLiteral(resourceName: "LineThickness15@167"), for: .normal)
        thickness20Button.setImage(#imageLiteral(resourceName: "LineThickness20@167"), for: .normal)
        thickness25Button.setImage(#imageLiteral(resourceName: "LineThickness25@167"), for: .normal)
        thickness30Button.setImage(#imageLiteral(resourceName: "LineThickness30@167"), for: .normal)
    }

}
