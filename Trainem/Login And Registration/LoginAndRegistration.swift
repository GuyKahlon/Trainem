//
//  LoginAndRegistration.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/9/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit

class RegistrationViewController: UIViewController{
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.rac_keyboardReturnSignal().subscribeNextAs { (textField: UITextField) -> () in
            if !textField.text!.isEmpty{
                self.passwordTextField.becomeFirstResponder()
            }
        }
        
        let validUsernameSignal = usernameTextField.rac_textSignal()
        .map { (text: AnyObject!) -> AnyObject! in
            if let email = text as? String{
                return self.isValidEmail(email)
            }
            return false
        }
        
        validUsernameSignal.map { (userNameValid:AnyObject!) -> AnyObject! in
            if let valid = userNameValid as? Bool where valid{
                return UIColor.yellowColor()
            }
            return UIColor.clearColor()
        }.subscribeNextAs { (color:UIColor) -> Void in
           self.usernameTextField.backgroundColor = color
        }
    
        let validPasswordSignal = passwordTextField.rac_textSignal().mapAs({ (password: String) -> NSNumber in
            return NSNumber(bool:self.isValidPassword(password))
        })
        
        validPasswordSignal.mapAs { (passwordIsValis: NSNumber) -> UIColor in
            if passwordIsValis.boolValue == true{
                return UIColor.yellowColor()
            }
            return UIColor.clearColor()
        }.subscribeNextAs { (color:UIColor) -> Void in
            self.passwordTextField.backgroundColor = color
        }
        
        let numbers = [ true, false]
        let total = numbers.reduce(true) { $0 && $1 }
        
        RACSignal.combineLatest([validUsernameSignal, validPasswordSignal])
        .mapAs({ (tuple: RACTuple) -> NSNumber in
                let bools = tuple.allObjects() as! [Bool]
                let valid = bools.reduce(true) { $0 && $1 }
                return NSNumber(bool: valid)
        })
        .subscribeNextAs { (valid: NSNumber!) -> Void in
            self.registerButton.enabled = valid.boolValue
            self.loginButton.enabled = valid.boolValue
        }
    }

    private func isValidEmail(email: String)->Bool{
        return (email as NSString).length > 3
    }
    
    private func isValidPassword(password: String)->Bool{
        return (password as NSString).length > 3
    }
}














