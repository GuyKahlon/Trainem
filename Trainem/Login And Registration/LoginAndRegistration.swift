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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

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
    
        let validPasswordSignal = passwordTextField.rac_textSignal()
        .mapAs({ (password: String) -> NSNumber in
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

        registerButton.rac_signalForControlEvents(.TouchUpInside)
        .doNext { _ in
            self.desableState()
        }
        .flattenMap(registerSignal)
        .subscribeNext { res in
            if let successfully = res as? Bool{
                println("Register successfully")
                self.gotoMainStoryboard()
            }
            else{
                let error = res as! NSError
                self.enableState()
                let meesage: String
                switch error.code{
                case ParseErrorsCode.RegisterUserAlreadyExist:
                    meesage = "User Already Exist"
                    break
                default: meesage = "Error has occurred, please try again later..."
                }
                
                let alert = UIAlertController(title: "Register Failure", message: meesage, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Close", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)

            }
        }
        
        loginButton.rac_signalForControlEvents(.TouchUpInside)
        .doNext { _ in
            self.desableState()
        }
        .flattenMap(signInSignal)
        .subscribeNext { res in
            if let user = res as? PFUser{
                println("Login successfully")
                self.gotoMainStoryboard()
            }
            else{
                let error = res as! NSError
                self.enableState()
                let meesage: String
                switch error.code{
                case ParseErrorsCode.LoginInvalidCardentials:
                    meesage = "Worng user name or password, Please try again"
                    break
                default: meesage = "Error has occurred, please try again later..."
                }
                
                let alert = UIAlertController(title: "Login Failure", message: meesage, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Close", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
   
    func registerSignal(_ : AnyObject!) -> RACSignal {
        return ParseUtilities.signUp(userName: usernameTextField.text, password: passwordTextField.text)
    }
    
    func signInSignal(_ : AnyObject!) -> RACSignal {
        return ParseUtilities.login(userName: usernameTextField.text, password: passwordTextField.text)
    }
    
    private func isValidEmail(email: String)->Bool{
        return (email as NSString).length > 3
    }
    
    private func isValidPassword(password: String)->Bool{
        return (password as NSString).length > 3
    }
    
    private func login()->NSNumber{
        return true
    }
    
    private func registration()->NSNumber{
        return true
    }
    
    private func desableState(){
        activityIndicator.startAnimating()
        loginButton.enabled = false
        registerButton.enabled = false
        view.endEditing(true)
    }
    
    private func enableState(){
        activityIndicator.stopAnimating()
        loginButton.enabled = true
        registerButton.enabled = true
    }
    
    private func gotoMainStoryboard(){
        let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let mainViewControlle = mainStoryboard.instantiateInitialViewController() as! UIViewController
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        dispatch_async(dispatch_get_main_queue(),{
            appDelegate.window?.rootViewController?.presentViewController(mainViewControlle, animated: true){
                activityIndicator.stopAnimating()
            }
        });
    }
}















