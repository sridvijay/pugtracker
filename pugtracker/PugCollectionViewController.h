//
//  PugCollectionViewController.h
//  pugtracker
//
//  Created by Vijay Sridhar on 6/24/15.
//  Copyright (c) 2015 sridvijay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>
#import <ZFDragableModalTransition/ZFModalTransitionAnimator.h>

@interface PugCollectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *pugCollectionView;
@property (strong, nonatomic) ZFModalTransitionAnimator *animator; // Open sourced view controller transition.
@property (strong, nonatomic) NSMutableArray *pugDataModel;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressRecognizer;

@end

