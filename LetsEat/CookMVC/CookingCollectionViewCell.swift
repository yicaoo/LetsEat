//
//  CookingCollectionViewCell.swift
//  FinalProject
//
//  Created by Yi Cao on 5/24/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import UIKit

class CookingCollectionViewCell: UICollectionViewCell, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageName: UITextField! {
        didSet {
            imageName.delegate = self
        }
    }
    
    // limit title to be no more than 12 letters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            let newLength = text.count + string.count - range.length
            return newLength <= TextFiledConstant.maxTitleLength
        } else {
            return false
        }
    }
    
    // press return on keyboard it goes away
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // closure which will be executed when the UITextField loses the first responder
    var textFieldResignationHandler: (() -> Void)?
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Calls the resignationHandler when the UITextField resigns first responder
        textFieldResignationHandler?()
    }
    
    private struct TextFiledConstant {
        static let maxTitleLength = 12
    }
}

