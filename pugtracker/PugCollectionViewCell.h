//
//  PugCollectionViewCell.h
//  
//
//  Created by Vijay Sridhar on 6/24/15.
//
//

#import <UIKit/UIKit.h>

@interface PugCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *pugImageView;
@property (weak, nonatomic) NSString *imageURL;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *weightLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperamentLabel;
@property (weak, nonatomic) IBOutlet UIButton *walkButton;
@property (weak, nonatomic) IBOutlet UIButton *feedButton;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *deadView;

@end
