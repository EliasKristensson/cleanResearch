//
//  HighlighterSettings.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2019-03-16.
//  Copyright © 2019 Elias Kristensson. All rights reserved.
//

import UIKit

internal class HighlighterSettings: UITableViewCell {

    @IBOutlet weak var splineOnButton: UIButton!
    
    @IBOutlet weak var splineOffButton: UIButton!
    
    @IBOutlet weak var highlighterColorsCV: UICollectionView!
    @IBOutlet weak var highlighterThicknessIndicator: UIButton!
    @IBOutlet weak var highlighterThicknessSlider: UISlider!
    @IBOutlet weak var highlighterAlphaSlider: UISlider!
    @IBOutlet weak var highlighterAlphaText: UILabel!
    @IBOutlet weak var highlighterOuterCircle: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let layoutHighlighter: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layoutHighlighter.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layoutHighlighter.itemSize = CGSize(width: highlighterColorsCV.bounds.width/8.5, height: highlighterColorsCV.bounds.width/8.5)
        layoutHighlighter.minimumInteritemSpacing = 2
        layoutHighlighter.minimumLineSpacing = 2
        highlighterColorsCV.collectionViewLayout = layoutHighlighter
        highlighterColorsCV.backgroundColor = UIColor.clear
        highlighterColorsCV.tag = 0
        highlighterColorsCV.remembersLastFocusedIndexPath = true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

internal class PenSettings: UITableViewCell {
    
    @IBOutlet weak var penThicknessSlider: UISlider!
    @IBOutlet weak var penColorsCV: UICollectionView!
    @IBOutlet weak var penThicknessIndicator: UIButton!
    @IBOutlet weak var penOuterCircle: UIView!
    
    @IBOutlet weak var splineOnButton: UIButton!
    
    @IBOutlet weak var splineOffButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let layoutHighlighter: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layoutHighlighter.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layoutHighlighter.itemSize = CGSize(width: penColorsCV.bounds.width/8.5, height: penColorsCV.bounds.width/8.5)
        layoutHighlighter.minimumInteritemSpacing = 2
        layoutHighlighter.minimumLineSpacing = 2
        penColorsCV.collectionViewLayout = layoutHighlighter
        penColorsCV.backgroundColor = UIColor.clear
        penColorsCV.tag = 1
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

internal class SaveSettings: UITableViewCell {
    
    @IBOutlet weak var saveTimeText: UILabel!
    
    @IBOutlet weak var saveTimeSlider: UISlider!
    
    @IBOutlet weak var saveButton: UIButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

internal class GradeSettings: UITableViewCell {
    
    @IBOutlet weak var gradeOnOff: UISwitch!
    
    @IBOutlet weak var gradesCV: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        gradesCV.tag = 2
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

internal class GradeCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    
    
}


internal class TextSettings: UITableViewCell {
    
    @IBOutlet weak var fontPicker: UIPickerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fontPicker.tag = 0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

internal class RulerSettings: UITableViewCell {
    
    @IBOutlet weak var lineWidthSlider: UISlider!
    @IBOutlet weak var lineWidthLabel: UILabel!
    @IBOutlet weak var lineAlphaSlider: UISlider!
    @IBOutlet weak var lineAlphaLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

internal class SpeakerSettings: UITableViewCell {
    
    @IBOutlet weak var voicePicker: UIPickerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        voicePicker.tag = 1
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

internal class AudioSettings: UITableViewCell {
    
    @IBOutlet weak var audioPicker: UIPickerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        audioPicker.tag = 2
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

internal class SubScoreCell: UITableViewCell {
    
    var mainScoreNumber: Int = 0
    
    @IBOutlet weak var scoreLabel: UILabel!
    
}

