//
//  UITextField+UITextField_RACKeyboardSupport.m
//  
//
//  Created by Guy Kahlon on 6/19/15.
//
//

#import "UITextField+RACKeyboardSupport.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/NSObject+RACDescription.h>


@implementation UITextField (RACKeyboardSupport)

- (RACSignal *)rac_keyboardReturnSignal {
    @weakify(self);
    return [[[[RACSignal
               defer:^{
                   @strongify(self);
                   return [RACSignal return:self];
               }]
              concat:[self rac_signalForControlEvents:UIControlEventEditingDidEndOnExit]]
             takeUntil:self.rac_willDeallocSignal]
            setNameWithFormat:@"%@ -rac_keyboardReturnSignal", [self rac_description]];
}
@end
