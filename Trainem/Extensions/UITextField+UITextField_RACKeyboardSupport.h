//
//  UITextField+UITextField_RACKeyboardSupport.h
//  
//
//  Created by Guy Kahlon on 6/19/15.
//
//

#import <UIKit/UIKit.h>
@class RACSignal;

@interface UITextField (UITextField_RACKeyboardSupport)
- (RACSignal *)rac_keyboardReturnSignal;
@end
