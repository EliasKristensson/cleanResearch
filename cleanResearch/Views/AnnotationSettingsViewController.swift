//
//  AnnotationSettingsViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2019-02-20.
//  Copyright © 2019 Elias Kristensson. All rights reserved.
//

import UIKit

class RulerTC: UITableViewCell {
    
}

class ColorCell: UICollectionViewCell {
    
}


class AnnotationSettingsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var loaded = false

    var grade = (add: false, type: "Approve", show: false) //add = update
    let grades = ["Approve", "Fail", "Warning", "Reading"]
    let order = ["Grades", "Save", "Highlighter", "Pen", "Text", "Ruler", "Speaker", "Audio"]
    
    var saveNow = false
    
    var highlighterColor: UIColor!
    var highligherThickness: CGFloat!
    var transparency: CGFloat!

    var penColor: UIColor!
    var penThickness: CGFloat!
    
    var annotationSettings: [Int]!
    
    var currentFile: LocalFile!
    var dataManager: DataManager!
    var pdfViewManager: PDFViewManager!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = false
        tableView.remembersLastFocusedIndexPath = true
        
        if let gradeData = dataManager.gradesCD.first(where: {$0.path == currentFile.path} ) {
            grade.show = gradeData.show
            grade.type = gradeData.type!
        }
        
        loaded = true
    }
    
    
    
    
    func getBackgroundColor(type: String) -> UIColor {
        var background = UIColor.init(red: 255*0.95, green: 255*0.95, blue: 255*0.95, alpha: 1)
        
        if let index = order.index(where: { $0 == type }) {
            if index % 2 == 0 || index == 0 {
                print("even")
                background = UIColor.init(red: 255*0.92, green: 255*0.92, blue: 255*0.92, alpha: 1)
            }
        }
        return background
    }

    func reloadTV(title: String) {
        if let row = order.index(where: { $0 == title }) {
            UIView.setAnimationsEnabled(false)
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            self.tableView.endUpdates()
        }
    }
    
    @objc func changeFontSize(sender: UIStepper) {
        annotationSettings[6] = Int(sender.value)
        
        reloadTV(title: "Text")
    }
    
    @objc func setHighlighterAlpha(sender: UISlider) {
        annotationSettings[4] = Int(100*sender.value)
        
        reloadTV(title: "Highlighter")
    }

    @objc func setHighlighterThickness(sender: UISlider) {
        annotationSettings[1] = Int(sender.value)

        reloadTV(title: "Highlighter")
    }

    @objc func setPenThickness(sender: UISlider) {
        annotationSettings[3] = Int(sender.value)
        
        reloadTV(title: "Pen")

    }
    
    @objc func setRulerWidth(sender: UISlider) {
        annotationSettings[17] = Int(sender.value)
        
        reloadTV(title: "Ruler")
    }

    @objc func setRulerAlpha(sender: UISlider) {
        annotationSettings[18] = Int(sender.value)
        
        reloadTV(title: "Ruler")
    }
    
    @objc func saveDoc(sender: UIButton) {
        saveNow = true
        dismiss(animated: true)
    }
    
    @objc func setTime(sender: UISlider) {
        annotationSettings[5] = Int(sender.value)
        
        reloadTV(title: "Save")

    }
    
    @objc func showOrHideGrade(sender: UISwitch) {
        grade.show = sender.isOn
        grade.add = true
    }
    
    @objc func switchHighlighterSpline(sender: UIButton) {
        annotationSettings[14] = sender.tag
        reloadTV(title: "Highlighter")
    }
    
    @objc func switchPenSpline(sender: UIButton) {
        annotationSettings[15] = sender.tag
        reloadTV(title: "Pen")
    }
    
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if order[indexPath.row] == "Highlighter" {
            return 275
        } else if order[indexPath.row] == "Pen" {
            return 245
        } else {
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return order.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if order[indexPath.row] == "Highlighter" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "highlighterSettings", for: indexPath) as! HighlighterSettings
            
            cell.highlighterAlphaSlider.tag = indexPath.row
            cell.highlighterAlphaSlider.value = Float(annotationSettings[4])/100
            cell.highlighterAlphaSlider.addTarget(self, action: #selector(setHighlighterAlpha), for: .valueChanged)
            cell.highlighterAlphaText.text = "Alpha: " + "\(annotationSettings[4])" + " %"
            
            cell.highlighterThicknessSlider.tag = indexPath.row
            cell.highlighterThicknessSlider.value = Float(annotationSettings[1])
            cell.highlighterThicknessSlider.addTarget(self, action: #selector(setHighlighterThickness), for: .valueChanged)
            
            cell.highlighterOuterCircle.frame = CGRect(x: cell.highlighterOuterCircle.frame.origin.x, y: cell.highlighterOuterCircle.frame.origin.y, width: 50, height: 50)
            cell.highlighterOuterCircle.layer.cornerRadius = cell.highlighterOuterCircle.frame.width/2
            cell.highlighterOuterCircle.layer.borderColor = UIColor.black.cgColor
            cell.highlighterOuterCircle.layer.borderWidth = 1
            
            highligherThickness = CGFloat(annotationSettings[1])
            cell.highlighterThicknessIndicator.frame = CGRect(x: cell.highlighterOuterCircle.frame.width/2-highligherThickness/2, y: cell.highlighterOuterCircle.frame.width/2-highligherThickness/2, width: highligherThickness, height: highligherThickness)
            cell.highlighterThicknessIndicator.layer.cornerRadius = highligherThickness/2
            
            cell.splineOnButton.layer.borderColor = UIColor.black.cgColor
            if annotationSettings[14] == 0 {
                cell.splineOnButton.layer.borderWidth = 2
            } else {
                cell.splineOnButton.layer.borderWidth = 0.5
            }
            cell.splineOnButton.tag = 0
            cell.splineOnButton.addTarget(self, action: #selector(switchHighlighterSpline), for: .touchUpInside)
            
            cell.splineOffButton.layer.borderColor = UIColor.black.cgColor
            if annotationSettings[14] == 1 {
                cell.splineOffButton.layer.borderWidth = 2
            } else {
                cell.splineOffButton.layer.borderWidth = 0.5
            }
            cell.splineOffButton.tag = 1
            cell.splineOffButton.addTarget(self, action: #selector(switchHighlighterSpline), for: .touchUpInside)

            let background = getBackgroundColor(type: "Highlighter")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            
            return cell
            
        } else if order[indexPath.row] == "Pen" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "penSettings", for: indexPath) as! PenSettings
            
            cell.penThicknessSlider.tag = indexPath.row
            cell.penThicknessSlider.value = Float(annotationSettings[3])
            cell.penThicknessSlider.addTarget(self, action: #selector(setPenThickness), for: .valueChanged)
            
            cell.penOuterCircle.frame = CGRect(x: cell.penOuterCircle.frame.origin.x, y: cell.penOuterCircle.frame.origin.y, width: 50, height: 50)
            cell.penOuterCircle.layer.cornerRadius = cell.penOuterCircle.frame.width/2
            cell.penOuterCircle.layer.borderColor = UIColor.black.cgColor
            cell.penOuterCircle.layer.borderWidth = 1

            penThickness = CGFloat(annotationSettings[3])
            cell.penThicknessIndicator.frame = CGRect(x: cell.penOuterCircle.frame.width/2-penThickness/2, y: cell.penOuterCircle.frame.width/2-penThickness/2, width: penThickness, height: penThickness)
            cell.penThicknessIndicator.layer.cornerRadius = penThickness/2
            
            cell.splineOnButton.layer.borderColor = UIColor.black.cgColor
            if annotationSettings[15] == 0 {
                cell.splineOnButton.layer.borderWidth = 2
            } else {
                cell.splineOnButton.layer.borderWidth = 0.5
            }
            cell.splineOnButton.tag = 0
            cell.splineOnButton.addTarget(self, action: #selector(switchPenSpline), for: .touchUpInside)
            
            cell.splineOffButton.layer.borderColor = UIColor.black.cgColor
            if annotationSettings[15] == 1 {
                cell.splineOffButton.layer.borderWidth = 2
            } else {
                cell.splineOffButton.layer.borderWidth = 0.5
            }
            cell.splineOffButton.tag = 1
            cell.splineOffButton.addTarget(self, action: #selector(switchPenSpline), for: .touchUpInside)

            let background = getBackgroundColor(type: "Pen")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            
            return cell
        
        } else if order[indexPath.row] == "Save" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "saveSettings", for: indexPath) as! SaveSettings
            
            cell.saveButton.addTarget(self, action: #selector(saveDoc), for: .touchUpInside)
            cell.saveTimeSlider.tag = indexPath.row
            cell.saveTimeSlider.value = Float(annotationSettings[5])
            cell.saveTimeSlider.addTarget(self, action: #selector(setTime), for: .valueChanged)
            if annotationSettings[5] > 0 {
                cell.saveTimeText.text = "\(annotationSettings[5])" + " min"
            } else {
                cell.saveTimeText.text = "Autosave: off"
            }
            
            let background = getBackgroundColor(type: "Save")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            
            return cell

        } else if order[indexPath.row] == "Grades" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "gradeSettings", for: indexPath) as! GradeSettings

            cell.gradeOnOff.addTarget(self, action: #selector(showOrHideGrade), for: .valueChanged)
            cell.gradeOnOff.isOn = grade.show
            
            let background = getBackgroundColor(type: "Grades")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            
            return cell
        
        } else if order[indexPath.row] == "Text" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "textSettings", for: indexPath) as! TextSettings
            
            cell.fontPicker.selectRow(annotationSettings[12], inComponent: 0, animated: false)
            cell.fontPicker.selectRow(annotationSettings[6]-5, inComponent: 1, animated: false)
            cell.fontPicker.selectRow(annotationSettings[13], inComponent: 2, animated: false)
            
            let background = getBackgroundColor(type: "Text")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            
            return cell
            
        } else if order[indexPath.row] == "Ruler" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "rulerSettings", for: indexPath) as! RulerSettings
            
            cell.lineWidthSlider.value = Float(annotationSettings[17])
            cell.lineWidthSlider.addTarget(self, action: #selector(setRulerWidth), for: .valueChanged)
            cell.lineWidthLabel.text = "Line: \(annotationSettings[17]) pt"

            cell.lineAlphaSlider.value = Float(annotationSettings[18])
            cell.lineAlphaSlider.addTarget(self, action: #selector(setRulerAlpha), for: .valueChanged)
            cell.lineAlphaLabel.text = "Alpha: \(annotationSettings[18]) %"

            let background = getBackgroundColor(type: "Ruler")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            
            return cell
            
        } else if order[indexPath.row] == "Speaker" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "speakerSettings", for: indexPath) as! SpeakerSettings
            
//            cell.speedSlider.value = Float(annotationSettings[21])
//            cell.speedSlider.addTarget(self, action: #selector(setSpeakerSpeed), for: .valueChanged)
//            cell.speedLabel.text = "Speed: \(annotationSettings[21]) %"
//
//            cell.pitchSlider.value = Float(annotationSettings[22])
//            cell.pitchSlider.addTarget(self, action: #selector(setSpeakerPitch), for: .valueChanged)
//            cell.pitchLabel.text = "Pitch: \(annotationSettings[22]) %"
            
            cell.voicePicker.selectRow(annotationSettings[20], inComponent: 0, animated: false)
            
            let background = getBackgroundColor(type: "Speaker")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            
            return cell
            
        } else if order[indexPath.row] == "Audio" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "audioSettings", for: indexPath) as! AudioSettings
            
            cell.audioPicker.selectRow(annotationSettings[21], inComponent: 0, animated: false)
            
            let background = getBackgroundColor(type: "Audio")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            
            return cell
            
        } else {
            
            let cell = UITableViewCell()
            let background = getBackgroundColor(type: "Highlighter")
            cell.contentView.backgroundColor = background
            cell.backgroundColor = background
            return cell
        }
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            return pdfViewManager.colors.count
        } else if collectionView.tag == 1 {
            return pdfViewManager.colors.count
        } else {
            return 4
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView.tag == 0 {
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "highlighterColorCell", for: indexPath) as! ColorCell
            
            var borderColor = UIColor.black.cgColor
            var borderWidth = CGFloat(1.5)
            
            if pdfViewManager.colors[indexPath.row][0] == 0 && pdfViewManager.colors[indexPath.row][1] == 0 && pdfViewManager.colors[indexPath.row][2] == 0 {
                borderColor = UIColor.white.cgColor
                borderWidth = 2.5
            }

            if indexPath.row == annotationSettings[0] {
                cell.layer.borderWidth = borderWidth
                cell.layer.borderColor = borderColor
                cell.layer.cornerRadius = cell.bounds.width/2
            } else {
                cell.layer.borderWidth = 0.25
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.cornerRadius = cell.bounds.width/2
            }
            
            cell.backgroundColor = UIColor(red: pdfViewManager.colors[indexPath.row][0], green: pdfViewManager.colors[indexPath.row][1], blue: pdfViewManager.colors[indexPath.row][2], alpha: 1)
            
            return cell
            
        } else if collectionView.tag == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "penColorCell", for: indexPath) as! ColorCell
            
            var borderColor = UIColor.black.cgColor
            var borderWidth = CGFloat(1.5)
            
            if pdfViewManager.colors[indexPath.row][0] == 0 && pdfViewManager.colors[indexPath.row][1] == 0 && pdfViewManager.colors[indexPath.row][2] == 0 {
                borderColor = UIColor.white.cgColor
                borderWidth = 2.5
            }
            
            if indexPath.row == annotationSettings[2] {
                cell.layer.borderWidth = borderWidth
                cell.layer.borderColor = borderColor
                cell.layer.cornerRadius = cell.bounds.width/2
            } else {
                cell.layer.borderWidth = 0.25
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.cornerRadius = cell.bounds.width/2
            }
            
            cell.backgroundColor = UIColor(red: pdfViewManager.colors[indexPath.row][0], green: pdfViewManager.colors[indexPath.row][1], blue: pdfViewManager.colors[indexPath.row][2], alpha: 1)

            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gradeCell", for: indexPath) as! GradeCell
            
            cell.image.alpha = 0.5
            
            switch indexPath.row {
            case 0:
                cell.image.image = #imageLiteral(resourceName: "Approved")
                if grade.type == "Approve" {
                    cell.image.alpha = 1
                }
            case 1:
                cell.image.image = #imageLiteral(resourceName: "Fail")
                if grade.type == "Fail" {
                    cell.image.alpha = 1
                }
            case 2:
                cell.image.image = #imageLiteral(resourceName: "Warning")
                if grade.type == "Warning" {
                    cell.image.alpha = 1
                }
            case 3:
                cell.image.image = #imageLiteral(resourceName: "Read")
                if grade.type == "Reading" {
                    cell.image.alpha = 1
                }
            default:
                cell.image.image = #imageLiteral(resourceName: "Approved")
                if grade.type == "Approve" {
                    cell.image.alpha = 1
                }
            }
            
            return cell
            
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if collectionView.tag == 0 {
            annotationSettings[0] = indexPath.row
            collectionView.reloadData()
        }
        if collectionView.tag == 1 {
            annotationSettings[2] = indexPath.row
            collectionView.reloadData()
        }
        if collectionView.tag == 2 {
            grade.add = true
            grade.show = true
            grade.type = grades[indexPath.row]
            reloadTV(title: "Grades")
            collectionView.reloadData()
            
        }
    }
    
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            if component == 0 {
                return pdfViewManager.fonts[row]
            } else if component == 1 {
                return pdfViewManager.fontSizes[row]
            } else {
                return pdfViewManager.fontTypes[row]
            }
        } else if pickerView.tag == 1 {
            return pdfViewManager.voices[row].language
        } else {
            return pdfViewManager.audio[row].language
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView.tag == 0 {
            return 3
        } else if pickerView.tag == 1 {
            return 1
        } else {
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            if component == 0 {
                return pdfViewManager.fonts.count
            } else if component == 1 {
                return pdfViewManager.fontSizes.count
            } else {
                return pdfViewManager.fontTypes.count
            }
        } else if pickerView.tag == 1 {
            return pdfViewManager.voices.count
        } else {
            return pdfViewManager.audio.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            if component == 0 {
                annotationSettings[12] = row
            } else if component == 1 {
                annotationSettings[6] = row+5
            } else {
                annotationSettings[13] = row
            }
        } else if pickerView.tag == 1 {
            annotationSettings[20] = row
        } else {
            annotationSettings[21] = row
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 0 {
            return 178
        } else if component == 1 {
            return 50
        } else if component == 2 {
            return 50
        } else {
            return 110
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.settingsHighlighter, object: self)
    }

}
