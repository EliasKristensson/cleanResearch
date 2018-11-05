//
//  PenSettingsViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-08-13.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class PenSettingsViewController: UIViewController {

    var fontSize: Int!
    
    var saveNow = false
    var highlightThicknesses: [CGFloat]!
    var penThicknesses: [CGFloat]!
    
    var highlighterColor: UIColor!
    var highligherThickness: CGFloat!
    var transparency: CGFloat!
    
    var penColor: UIColor!
    var penThickness: CGFloat!
    
    var selectedSettings: [Int]!
    var autoSaveTime: Int!
    
    // MARK:- IBOutlets
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
    
    @IBOutlet weak var thicknessPen1Button: UIButton!
    @IBOutlet weak var thicknessPen2Button: UIButton!
    @IBOutlet weak var thicknessPen3Button: UIButton!
    @IBOutlet weak var thicknessPen4Button: UIButton!
    @IBOutlet weak var thicknessPen5Button: UIButton!
    @IBOutlet weak var bluePenButton: UIButton!
    @IBOutlet weak var redPenButton: UIButton!
    @IBOutlet weak var greenPenButton: UIButton!
    @IBOutlet weak var blackPenButton: UIButton!
    @IBOutlet weak var grayPenButton: UIButton!
    @IBOutlet weak var transparencySlider: UISlider!
    @IBOutlet weak var autoSaveTimeText: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var transparencyText: UILabel!
    @IBOutlet weak var fontSizeStepper: UIStepper!
    @IBOutlet weak var fontSizeLabel: UILabel!
    
    
    // MARK:- IBActions
    @IBAction func fontSizeStepperTapped(_ sender: Any) {
        fontSize = Int(fontSizeStepper.value)
        selectedSettings[6] = fontSize
        fontSizeLabel.text = "\(fontSize!)" + " pt"
    }
    
    @IBAction func timeSliderChanged(_ sender: Any) {
        autoSaveTime = Int(timeSlider!.value)
        setTime(time: autoSaveTime)
    }
    
    @IBAction func transparencyChanged(_ sender: Any) {
        transparency = CGFloat(transparencySlider.value)
        selectedSettings[4] = Int(100*transparency)
        transparencyText.text = "Transparency: " + "\(selectedSettings[4])" + " %"
        if selectedSettings[0] == 0 {
            highlighterColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: transparency)
        } else if selectedSettings[0] == 1 {
            highlighterColor = UIColor(red: 255/255.0, green: 0/255.0, blue: 0/255.0, alpha: transparency)
        } else if selectedSettings[0] == 2 {
            highlighterColor = UIColor(red: 0/255.0, green: 255/255.0, blue: 0/255.0, alpha: transparency)
        } else if selectedSettings[0] == 3 {
            highlighterColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 0/255.0, alpha: transparency)
        } else if selectedSettings[0] == 4 {
            highlighterColor = UIColor(red: 85/255.0, green: 85/255.0, blue: 85/255.0, alpha: transparency)
        }
    }
    
    @IBAction func blueHighlighter(_ sender: Any) {
        transparency = CGFloat(transparencySlider.value)
        highlighterColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: transparency)
        unselectColors(type: "Highlight")
        blueButton.setImage(#imageLiteral(resourceName: "BlueHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 0
        selectedSettings[4] = Int(100*transparency)
    }
    @IBAction func redHighlighter(_ sender: Any) {
        transparency = CGFloat(transparencySlider.value)
        highlighterColor = UIColor(red: 255/255.0, green: 0/255.0, blue: 0/255.0, alpha: transparency)
        unselectColors(type: "Highlight")
        redButton.setImage(#imageLiteral(resourceName: "RedHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 1
        selectedSettings[4] = Int(100*transparency)
    }
    @IBAction func greenHighlighter(_ sender: Any) {
        transparency = CGFloat(transparencySlider.value)
        highlighterColor = UIColor(red: 0/255.0, green: 255/255.0, blue: 0/255.0, alpha: transparency)
        unselectColors(type: "Highlight")
        greenButton.setImage(#imageLiteral(resourceName: "GreenHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 2
        selectedSettings[4] = Int(100*transparency)
    }
    @IBAction func yellowHighlighter(_ sender: Any) {
        transparency = CGFloat(transparencySlider.value)
        highlighterColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 0/255.0, alpha: transparency)
        unselectColors(type: "Highlight")
        yellowButton.setImage(#imageLiteral(resourceName: "YellowHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 3
        selectedSettings[4] = Int(100*transparency)
    }
    @IBAction func grayHighlighter(_ sender: Any) {
        transparency = CGFloat(transparencySlider.value)
        highlighterColor = UIColor(red: 85/255.0, green: 85/255.0, blue: 85/255.0, alpha: transparency)
        unselectColors(type: "Highlight")
        grayButton.setImage(#imageLiteral(resourceName: "GrayHighlighterSelected@167px"), for: .normal)
        selectedSettings[0] = 4
        selectedSettings[4] = Int(100*transparency)
    }
    
    @IBAction func thickness10(_ sender: Any) {
        highligherThickness = highlightThicknesses[0]
        unselectLine(type: "Highlight")
        thickness10Button.setImage(#imageLiteral(resourceName: "LineThickness10Selected@167"), for: .normal)
        selectedSettings[1] = 0
    }
    @IBAction func thickness15(_ sender: Any) {
        highligherThickness = highlightThicknesses[1]
        unselectLine(type: "Highlight")
        thickness15Button.setImage(#imageLiteral(resourceName: "LineThickness15Selected@167"), for: .normal)
        selectedSettings[1] = 1
    }
    @IBAction func thickness20(_ sender: Any) {
        highligherThickness = highlightThicknesses[2]
        unselectLine(type: "Highlight")
        thickness20Button.setImage(#imageLiteral(resourceName: "LineThickness20Selected@167"), for: .normal)
        selectedSettings[1] = 2
    }
    @IBAction func thickness25(_ sender: Any) {
        highligherThickness = highlightThicknesses[3]
        unselectLine(type: "Highlight")
        thickness25Button.setImage(#imageLiteral(resourceName: "LineThickness25Selected@167"), for: .normal)
        selectedSettings[1] = 3
    }
    @IBAction func thickness30(_ sender: Any) {
        highligherThickness = highlightThicknesses[4]
        unselectLine(type: "Highlight")
        thickness30Button.setImage(#imageLiteral(resourceName: "LineThickness30Selected@167"), for: .normal)
        selectedSettings[1] = 4
    }
    
    
    
    @IBAction func bluePen(_ sender: Any) {
        penColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 1)
        unselectColors(type: "Pen")
        bluePenButton.setImage(#imageLiteral(resourceName: "BluePenSelected"), for: .normal)
        selectedSettings[2] = 0
    }
    @IBAction func redPen(_ sender: Any) {
        penColor = UIColor(red: 0/255.0, green: 255/255.0, blue: 0/255.0, alpha: 1)
        unselectColors(type: "Pen")
        redPenButton.setImage(#imageLiteral(resourceName: "RedPenSelected"), for: .normal)
        selectedSettings[2] = 1
    }
    @IBAction func greenPen(_ sender: Any) {
        penColor = UIColor(red: 0/255.0, green: 255/255.0, blue: 0/255.0, alpha: 1)
        unselectColors(type: "Pen")
        greenPenButton.setImage(#imageLiteral(resourceName: "GreenPenSelected"), for: .normal)
        selectedSettings[2] = 2
    }
    @IBAction func blackPen(_ sender: Any) {
        penColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1)
        unselectColors(type: "Pen")
        blackPenButton.setImage(#imageLiteral(resourceName: "BlackPenSelected"), for: .normal)
        selectedSettings[2] = 3
    }
    @IBAction func grayPen(_ sender: Any) {
        penColor = UIColor(red: 85/255.0, green: 85/255.0, blue: 85/255.0, alpha: 1)
        unselectColors(type: "Pen")
        grayPenButton.setImage(#imageLiteral(resourceName: "GrayPenSelected"), for: .normal)
        selectedSettings[2] = 4
    }
    
    
    @IBAction func penThickness1(_ sender: Any) {
        penThickness = penThicknesses[0]
        unselectLine(type: "Pen")
        thicknessPen1Button.setImage(#imageLiteral(resourceName: "Pen1Selected.png"), for: .normal)
        selectedSettings[3] = 0
    }
    @IBAction func penThickness2(_ sender: Any) {
        penThickness = penThicknesses[1]
        unselectLine(type: "Pen")
        thicknessPen2Button.setImage(#imageLiteral(resourceName: "Pen2Selected.png"), for: .normal)
        selectedSettings[3] = 1
    }
    @IBAction func penThickness3(_ sender: Any) {
        penThickness = penThicknesses[2]
        unselectLine(type: "Pen")
        thicknessPen3Button.setImage(#imageLiteral(resourceName: "Pen3Selected.png"), for: .normal)
        selectedSettings[3] = 2
    }
    @IBAction func penThickness4(_ sender: Any) {
        penThickness = penThicknesses[3]
        unselectLine(type: "Pen")
        thicknessPen4Button.setImage(#imageLiteral(resourceName: "Pen4Selected.png"), for: .normal)
        selectedSettings[3] = 3
    }
    @IBAction func penThickness5(_ sender: Any) {
        penThickness = penThicknesses[4]
        unselectLine(type: "Pen")
        thicknessPen5Button.setImage(#imageLiteral(resourceName: "Pen5Selected.png"), for: .normal)
        selectedSettings[3] = 4
    }
    
    @IBAction func saveNowTapped(_ sender: Any) {
        saveNow = true
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        unselectColors(type: "Highlight")
        unselectLine(type: "Highlight")
        unselectColors(type: "Pen")
        unselectLine(type: "Pen")
        
        if selectedSettings.count < 9 {
            selectedSettings = [3, 3, 3, 3, 50, 15, 0, 0, 0]
        }
        
        switch selectedSettings[0] {
        case 0:
            blueButton.setImage(#imageLiteral(resourceName: "BlueHighlighterSelected@167px"), for: .normal)
        case 1:
            redButton.setImage(#imageLiteral(resourceName: "RedHighlighterSelected@167px"), for: .normal)
        case 2:
            greenButton.setImage(#imageLiteral(resourceName: "GreenHighlighterSelected@167px"), for: .normal)
        case 3:
            yellowButton.setImage(#imageLiteral(resourceName: "YellowHighlighterSelected@167px"), for: .normal)
        case 4:
            grayButton.setImage(#imageLiteral(resourceName: "GrayHighlighterSelected@167px"), for: .normal)
        default:
            blueButton.setImage(#imageLiteral(resourceName: "BlueHighlighterSelected@167px"), for: .normal)
        }
        switch selectedSettings[1] {
        case 0:
            thickness10Button.setImage(#imageLiteral(resourceName: "Highlight1Selected.png"), for: .normal)
        case 1:
            thickness15Button.setImage(#imageLiteral(resourceName: "Highlight2Selected.png"), for: .normal)
        case 2:
            thickness20Button.setImage(#imageLiteral(resourceName: "Highlight3Selected.png"), for: .normal)
        case 3:
            thickness25Button.setImage(#imageLiteral(resourceName: "Highlight4Selected.png"), for: .normal)
        case 4:
            thickness30Button.setImage(#imageLiteral(resourceName: "Highlight5Selected.png"), for: .normal)
        default:
            thickness10Button.setImage(#imageLiteral(resourceName: "Highlight1Selected.png"), for: .normal)
        }
        switch selectedSettings[2] {
        case 0:
            bluePenButton.setImage(#imageLiteral(resourceName: "BluePenSelected.png"), for: .normal)
        case 1:
            redPenButton.setImage(#imageLiteral(resourceName: "RedPenSelected.png"), for: .normal)
        case 2:
            greenPenButton.setImage(#imageLiteral(resourceName: "GreenPenSelected.png"), for: .normal)
        case 3:
            blackPenButton.setImage(#imageLiteral(resourceName: "BlackPenSelected.png"), for: .normal)
        case 4:
            grayPenButton.setImage(#imageLiteral(resourceName: "GrayPenSelected.png"), for: .normal)
        default:
            blackPenButton.setImage(#imageLiteral(resourceName: "BlackPenSelected.png"), for: .normal)
        }
        switch selectedSettings[3] {
        case 0:
            thicknessPen1Button.setImage(#imageLiteral(resourceName: "Pen1Selected.png"), for: .normal)
        case 1:
            thicknessPen2Button.setImage(#imageLiteral(resourceName: "Pen2Selected.png"), for: .normal)
        case 2:
            thicknessPen3Button.setImage(#imageLiteral(resourceName: "Pen3Selected.png"), for: .normal)
        case 3:
            thicknessPen4Button.setImage(#imageLiteral(resourceName: "Pen4Selected.png"), for: .normal)
        case 4:
            thicknessPen5Button.setImage(#imageLiteral(resourceName: "Pen5Selected.png"), for: .normal)
        default:
            thicknessPen1Button.setImage(#imageLiteral(resourceName: "Pen1Selected.png"), for: .normal)
        }
        transparencySlider.value = Float(selectedSettings[4])/100
        transparencyText.text = "Transparency: " + "\(selectedSettings[4])" + " %"
        autoSaveTime = selectedSettings[5]
        timeSlider.value = Float(autoSaveTime)
        setTime(time: autoSaveTime)
        fontSize = selectedSettings[6]
        fontSizeStepper.value = Double(fontSize)
        fontSizeLabel.text = "\(fontSize!)" + " pt"
    }

    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.settingsHighlighter, object: self)
    }
    
    func unselectColors(type: String) {
        if type == "Highlight" {
            blueButton.setImage(#imageLiteral(resourceName: "BlueHighlighter@167px"), for: .normal)
            redButton.setImage(#imageLiteral(resourceName: "RedHighlighter@167px"), for: .normal)
            greenButton.setImage(#imageLiteral(resourceName: "GreenHighlighter@167px"), for: .normal)
            yellowButton.setImage(#imageLiteral(resourceName: "YellowHighlighter@167px"), for: .normal)
            grayButton.setImage(#imageLiteral(resourceName: "GrayHighlighter@167px"), for: .normal)
        } else if type == "Pen" {
            bluePenButton.setImage(#imageLiteral(resourceName: "BluePen"), for: .normal)
            redPenButton.setImage(#imageLiteral(resourceName: "RedPen"), for: .normal)
            greenPenButton.setImage(#imageLiteral(resourceName: "GreenPen.png"), for: .normal)
            blackPenButton.setImage(#imageLiteral(resourceName: "BlackPen.png"), for: .normal)
            grayPenButton.setImage(#imageLiteral(resourceName: "GrayPen.png"), for: .normal)
        }
    }
    
    func unselectLine(type: String) {
        if type == "Highlight" {
            thickness10Button.setImage(#imageLiteral(resourceName: "LineThickness10@167"), for: .normal)
            thickness15Button.setImage(#imageLiteral(resourceName: "LineThickness15@167"), for: .normal)
            thickness20Button.setImage(#imageLiteral(resourceName: "LineThickness20@167"), for: .normal)
            thickness25Button.setImage(#imageLiteral(resourceName: "LineThickness25@167"), for: .normal)
            thickness30Button.setImage(#imageLiteral(resourceName: "LineThickness30@167"), for: .normal)
        } else if type == "Pen" {
            thicknessPen1Button.setImage(#imageLiteral(resourceName: "Pen1.png"), for: .normal)
            thicknessPen2Button.setImage(#imageLiteral(resourceName: "Pen2.png"), for: .normal)
            thicknessPen3Button.setImage(#imageLiteral(resourceName: "Pen3.png"), for: .normal)
            thicknessPen4Button.setImage(#imageLiteral(resourceName: "Pen4.png"), for: .normal)
            thicknessPen5Button.setImage(#imageLiteral(resourceName: "Pen5.png"), for: .normal)
        }
    }

    func setTime(time: Int) {
        if time > 0 {
            autoSaveTimeText.text = "Autosave time: " + "\(time)" + " min"
            autoSaveTime = time
        } else {
            autoSaveTimeText.text = "Autosave time: off"
            autoSaveTime = 0
        }
        selectedSettings[5] = autoSaveTime
        
    }

    
}
