//
//  AddPugViewController.h
//  pugtracker
//
//  Created by Vijay Sridhar on 6/26/15.
//  Copyright © 2015 sridvijay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddPugViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *weightField;
@property (weak, nonatomic) IBOutlet UITextField *temperamentField;

@end
