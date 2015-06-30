//
//  AddPugViewController.m
//  pugtracker
//
//  Created by Vijay Sridhar on 6/26/15.
//  Copyright © 2015 sridvijay. All rights reserved.
//

#import "AddPugViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "AppDelegate.h"
#import "Pug.h"

@interface AddPugViewController () {
    AppDelegate *appD;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLayoutConstraint;

@end

@implementation AddPugViewController

- (void)viewDidLoad {
    
    // Sets how far up the view controller goes since it's a semi-modal transition (AKA the entire view controller is not visible). This is to offset the keyboard.
    int screenHeight = [[UIScreen mainScreen] bounds].size.height;
    switch (screenHeight) {
        case 480: // iPhone 4S
            self.topLayoutConstraint.constant = 5;
            break;
            
        case 568: // iPhone 5
            self.topLayoutConstraint.constant = 92;
            break;
            
        case 736: // iPhone 6 Plus
            self.topLayoutConstraint.constant = 242;
            break;
            
        default: // iPhone 6
            self.topLayoutConstraint.constant = 186;
            break;
    }
    
    // Programatically adding the appropriate icons to the textfields. (on the left)
    
    UIView *leftPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    UIImageView *leftNameIcon = [[UIImageView alloc] initWithFrame:CGRectMake(5, 0, 40, 50)];
    leftNameIcon.contentMode = UIViewContentModeScaleAspectFit;
    leftNameIcon.image = [UIImage imageNamed:@"pugName"];
    [leftPadding addSubview:leftNameIcon];
    self.nameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.nameTextField.leftView = leftPadding;
    self.nameTextField.delegate = self;
    
    UIView *leftPadding2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    UIImageView *leftNameIcon2 = [[UIImageView alloc] initWithFrame:CGRectMake(5, 0, 40, 50)];
    leftNameIcon2.contentMode = UIViewContentModeScaleAspectFit;
    leftNameIcon2.image = [UIImage imageNamed:@"weightIcon"];
    [leftPadding2 addSubview:leftNameIcon2];
    self.weightField.leftViewMode = UITextFieldViewModeAlways;
    self.weightField.leftView = leftPadding2;
    self.weightField.delegate = self;
    
    UIView *leftPadding3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    UIImageView *leftNameIcon3 = [[UIImageView alloc] initWithFrame:CGRectMake(5, 0, 40, 50)];
    leftNameIcon3.contentMode = UIViewContentModeScaleAspectFit;
    leftNameIcon3.image = [UIImage imageNamed:@"emotionIcon"];
    [leftPadding3 addSubview:leftNameIcon3];
    self.temperamentField.leftViewMode = UITextFieldViewModeAlways;
    self.temperamentField.leftView = leftPadding3;
    self.temperamentField.delegate = self;
    
    // Get keyboard to pop-up for first text field.
    [self.nameTextField becomeFirstResponder];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameTextField) {
        [self.weightField becomeFirstResponder];
    } else if (textField == self.temperamentField) {
        [self resignFirstResponder];
        [self saveNewPug:self];
    }
    return YES;
}

- (IBAction)saveNewPug:(id)sender {
    
    // Make sure pug weight is within limit between 13 and 20 pounds.
    if (self.weightField.text.doubleValue <= 20 && self.weightField.text.doubleValue >= 13) {
        appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        Pug *pug = [NSEntityDescription insertNewObjectForEntityForName:@"Pug"
                                                 inManagedObjectContext:appD.managedObjectContext];
        pug.name = self.nameTextField.text;
        pug.weight = [NSNumber numberWithDouble:self.weightField.text.doubleValue];
        pug.temperament = self.temperamentField.text;
        
        // Download random pug image and then save the pug. Sends notification to ViewController to reload collection view data source.
        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://pugme.herokuapp.com/random"]]];
        requestOperation.responseSerializer = [AFJSONResponseSerializer serializer];
        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *URL = [responseObject objectForKey:@"pug"];
            UIImage *pugImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", URL]]]];
            pug.image = UIImagePNGRepresentation(pugImage);
            [appD.managedObjectContext save:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:pug];
            [self dismissViewControllerAnimated:YES completion:nil];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Image error: %@", error);
        }];
        
        [requestOperation start];
    } else {
        // Alert user if pug is not within correct weight limits.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"Your pug must have a weight between 13 and 20 pounds for it to be healthy!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
