//
//  UIKitExtension.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/26/15.
//  Copyright © 2015 GuyKahlon. All rights reserved.
//

import Foundation

extension CALayer{
    
    func setBorderUIColor(color: UIColor){
        borderColor = color.CGColor
    }
    
    func borderUIColor()->UIColor{
        return UIColor(CGColor: self.borderColor!)
    }
}

extension UIView{
    
    func removeGlowToView(){
        
        self.layer.shadowOpacity = 0
        self.layer.shadowRadius = 0
        self.layer.masksToBounds = true
    }
    
    func setGlowToView(color: UIColor){
        let bezierPath = UIBezierPath(rect: self.bounds)
        self.layer.shadowPath = bezierPath.CGPath
        self.layer.shadowOffset = CGSizeMake(0, 0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 5
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.CGColor
        
    }
}