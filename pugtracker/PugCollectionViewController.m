//
//  PugCollectionViewController.m
//  pugtracker
//
//  Created by Vijay Sridhar on 6/24/15.
//  Copyright (c) 2015 sridvijay. All rights reserved.
//

#import "PugCollectionViewController.h"
#import "AppDelegate.h"
#import "Pug.h"
#import <CoreData/CoreData.h>
#import <JGProgressHUD/JGProgressHUD.h>
#import "PugCollectionViewCell.h"
#import <pop/POP.h>
#import "AddPugViewController.h"

@interface PugCollectionViewController () {
    AppDelegate *appD;
    NSArray *temperaments;
    NSIndexPath *selectedIndexPath;
    JGProgressHUD *HUD;
}

@end

@implementation PugCollectionViewController

- (void)viewDidLoad {
    self.pugDataModel = [[NSMutableArray alloc] initWithCapacity:0];
    
    // An array of default temperaments. Later randomly selected for a pug (that is not added manually).
    temperaments = @[@"Exhausted. Spends time watching you.", @"Hungry. Spends all its time eating.", @"Musical. Listens to Waka Flocka Flame.", @"Bored. Spends time watching FRIENDS.", @"Lonely. Thinks about other pugs.", @"Amicable. Spends time cuddling w/ you.", @"Excited. Runs around house into walls.", @"Angry. Constantly barks at inanimate objects."];
    
    appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Check if this is first launch (to create initial dataset) or to retrieve an existing dataset.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Pug" inManagedObjectContext:appD.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [appD.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    if ([fetchedObjects count] == 0) {
        NSLog(@"Creating Initial Dataset");

        HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        HUD.textLabel.text = @"Creating Initial Dataset...";
        [HUD showInView:self.view];
        
        [self createDefaultDataSet];
    } else {
        NSLog(@"Retrieving Existing Dataset");
        
        for (Pug *pug in fetchedObjects) {
            [self.pugDataModel addObject:pug];
            NSLog(@"Name: %@", [pug valueForKey:@"name"]);
            NSLog(@"Weight: %@", [pug valueForKey:@"weight"]);
            NSLog(@"Temperament: %@", [pug valueForKey:@"temperament"]);
        }
    }
    
    // BEGIN: Nifty animation that emphasizes the center cell and de-emphasizes (scales down, lowers alpha) the side cells.
    // See scrollViewWillEndDragging: at line ~186 for step by step breakdown.
    dispatch_async(dispatch_get_main_queue(), ^{ // make sure its on main queue since its an animation. (otherwise it won't work!)
        NSIndexPath *indexPath;
        if ([self.pugCollectionView indexPathForItemAtPoint:CGPointMake(80 + self.pugCollectionView.contentOffset.x, 250)] != nil) {
            indexPath = [NSIndexPath indexPathForRow:[self.pugCollectionView indexPathForItemAtPoint:CGPointMake(80 + self.pugCollectionView.contentOffset.x, 250)].row inSection:0];
            selectedIndexPath = indexPath;
            [self.pageControl setCurrentPage:indexPath.row];
        }

        UICollectionViewCell *cell = [self.pugCollectionView cellForItemAtIndexPath:indexPath];
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        anim.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
        [cell.layer pop_addAnimation:anim forKey:@"bigger"];
        POPBasicAnimation *alpha = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        alpha.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        alpha.toValue = @(1.0);
        [cell.layer pop_addAnimation:alpha forKey:@"fade"];
    });
    
    // END

    // When new pug is added.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCollectionView:) name:@"refresh" object:nil];
    [super viewDidLoad];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    int screenHeight = [[UIScreen mainScreen] bounds].size.height;
    int edgeInset;
    
    switch (screenHeight) {
        case 480: // iPhone 4S
            edgeInset = 43;
            break;
            
        case 568: // iPhone 5
            edgeInset = 37;
            break;
            
        case 736: // iPhone 6 Plus
            edgeInset = 40;
            break;
            
        default: // iPhone 6
            edgeInset = 42;
            break;
    }
    
    // Set proper edge inset depending on device screen size (since different displays have different collection view cell sizes)
    return UIEdgeInsetsMake(0, edgeInset, 0, edgeInset);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    int screenHeight = [[UIScreen mainScreen] bounds].size.height;
    switch (screenHeight) {
        case 480: // iPhone 4S
            return CGSizeMake(234.0f, 320.0f);
            break;
            
        case 568: // iPhone 5
            return CGSizeMake(246.0f, 356.0f);
            break;
            
        case 736: // iPhone 6 Plus
            return CGSizeMake(334.0f, 480.0f);
            break;
            
        default: // iPhone 6
            return CGSizeMake(290.0f, 418.0f);
            break;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    // BEGIN: Custom paging mechanism, because collection views can't page properly with edge insets...ugh thanks Apple.
    
    int screenHeight = [[UIScreen mainScreen] bounds].size.height;
    int pageWidth;
    switch (screenHeight) {
        case 480: // iPhone 4S
            pageWidth = 244;
            break;
            
        case 568: // iPhone 5
            pageWidth = 256;
            break;
            
        case 736: // iPhone 6 Plus
            pageWidth = 344;
            break;
            
        default: // iPhone 6
            pageWidth = 300;
            break;
    }
    
    float currentOffset = scrollView.contentOffset.x;
    float targetOffset = targetContentOffset->x;
    float newTargetOffset = 0;
    
    if (targetOffset > currentOffset)
        newTargetOffset = ceilf(currentOffset / pageWidth) * pageWidth;
    else
        newTargetOffset = floorf(currentOffset / pageWidth) * pageWidth;
    
    if (newTargetOffset < 0)
        newTargetOffset = 0;
    else if (newTargetOffset > scrollView.contentSize.width)
        newTargetOffset = scrollView.contentSize.width;
    
    targetContentOffset->x = currentOffset;
    [scrollView setContentOffset:CGPointMake(newTargetOffset, 0) animated:YES];
    
    // END
    
    // BEGIN: Nifty animation that emphasizes the center cell and de-emphasizes (scales down, lowers alpha) the side cells.
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath;
        
        // Checks and figures out index path of the cell that is visibly in the center of the display.
        if ([self.pugCollectionView indexPathForItemAtPoint:CGPointMake(pageWidth + newTargetOffset, 250)] != nil) {
            indexPath = [NSIndexPath indexPathForRow:[self.pugCollectionView indexPathForItemAtPoint:CGPointMake(pageWidth + newTargetOffset, 250)].row inSection:0];
            selectedIndexPath = indexPath;
            [self.pageControl setCurrentPage:indexPath.row]; // set page control current page while we're here
        }
        
        UICollectionViewCell *cell = [self.pugCollectionView cellForItemAtIndexPath:indexPath]; // center cell
        
        POPBasicAnimation *scaleUp = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY]; // makes sure scale is at 100%
        scaleUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        scaleUp.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
        [cell.layer pop_addAnimation:scaleUp forKey:@"scaleCellUp"];
        POPBasicAnimation *opacityNormal = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity]; // makes sure alpha is at 100%
        opacityNormal.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        opacityNormal.toValue = @(1.0);
        [cell.layer pop_addAnimation:opacityNormal forKey:@"cellOpacityNormal"];
        
        NSIndexPath *beforeIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0]; // cell to the left of the center cell. If no cell, then this is nil.
        UICollectionViewCell *beforeCell = [self.pugCollectionView cellForItemAtIndexPath:beforeIndexPath];
        NSIndexPath *afterIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]; // cell to the right of the center cell. If no cell, then this is nil.
        UICollectionViewCell *afterCell = [self.pugCollectionView cellForItemAtIndexPath:afterIndexPath];
        
        POPBasicAnimation *scaleDown = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY]; // animate scale down to 90%
        scaleDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        scaleDown.toValue = [NSValue valueWithCGPoint:CGPointMake(0.9, 0.9)];
        POPBasicAnimation *opacityDown = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity]; // animate fade to 80% opacity
        opacityDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        opacityDown.toValue = @(0.8);
        
        // Add animation to both left and right cells.
        [beforeCell.layer pop_addAnimation:scaleDown forKey:@"scaleCellDown"];
        [beforeCell.layer pop_addAnimation:opacityDown forKey:@"fadeCellDown"];
        
        [afterCell.layer pop_addAnimation:scaleDown forKey:@"scaleCellDown"];
        [afterCell.layer pop_addAnimation:opacityDown forKey:@"fadeCellDown"];
    });
    
    // END
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    // Makes sure that cell is de-emphasized when entering collection view without animating in. This solves the problem with dequeueing/reusing cells.
    if (selectedIndexPath != indexPath) {
        cell.layer.transform = CATransform3DMakeScale(.9, .9, 1);
        cell.layer.opacity = 0.8;
    } else {
        cell.layer.transform = CATransform3DMakeScale(1, 1, 1);
        cell.layer.opacity = 1.0;
    }
}

- (void)refreshCollectionView:(NSNotification *)notification {
    // Add new pug into collection view.
    
    Pug *newPug = (Pug *)notification.object;
    [self.pugDataModel addObject:newPug];
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.pugCollectionView performBatchUpdates:^{
            [self.pugCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        } completion:^(BOOL finished) {
            [self resetEmphasizedCells];
        }];
    });
}

- (IBAction)deletePug:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"UIGestureRecognizerStateEnded");
        UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Pressing OK will delete this pug!" delegate:self cancelButtonTitle:@"No!" otherButtonTitles:@"Ok", nil];
        [deleteAlert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // OK button pressed.
        Pug *selectedPug = [self.pugDataModel objectAtIndex:self.pageControl.currentPage];
        
        // Delete pug from core data.
        NSManagedObjectContext *context = [appD managedObjectContext];
        NSError *error;
        [context deleteObject:selectedPug];
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        // Delete pug from local datasource.
        [self.pugDataModel removeObjectAtIndex:self.pageControl.currentPage];
        // Reload collection view.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pugCollectionView performBatchUpdates:^{
                [self.pugCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            } completion:^(BOOL finished) {
                [self resetEmphasizedCells];
            }];
        });
    }
}

- (void)resetEmphasizedCells {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath;
        
        // Checks and figures out index path of the cell that is visibly in the center of the display.
        if ([self.pugCollectionView indexPathForItemAtPoint:CGPointMake(self.pugCollectionView.contentOffset.x + (self.view.frame.size.width/2), 250)] != nil) {
            indexPath = [NSIndexPath indexPathForRow:[self.pugCollectionView indexPathForItemAtPoint:CGPointMake(self.pugCollectionView.contentOffset.x + (self.view.frame.size.width/2), 250)].row inSection:0];
            selectedIndexPath = indexPath;
            [self.pageControl setCurrentPage:indexPath.row]; // set page control current page while we're here
        }
        
        UICollectionViewCell *cell = [self.pugCollectionView cellForItemAtIndexPath:indexPath]; // center cell
        
        POPBasicAnimation *scaleUp = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY]; // makes sure scale is at 100%
        scaleUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        scaleUp.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
        [cell.layer pop_addAnimation:scaleUp forKey:@"scaleCellUp"];
        POPBasicAnimation *opacityNormal = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity]; // makes sure alpha is at 100%
        opacityNormal.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        opacityNormal.toValue = @(1.0);
        [cell.layer pop_addAnimation:opacityNormal forKey:@"cellOpacityNormal"];
        
        NSIndexPath *beforeIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0]; // cell to the left of the center cell. If no cell, then this is nil.
        UICollectionViewCell *beforeCell = [self.pugCollectionView cellForItemAtIndexPath:beforeIndexPath];
        NSIndexPath *afterIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]; // cell to the right of the center cell. If no cell, then this is nil.
        UICollectionViewCell *afterCell = [self.pugCollectionView cellForItemAtIndexPath:afterIndexPath];
        
        POPBasicAnimation *scaleDown = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY]; // animate scale down to 90%
        scaleDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        scaleDown.toValue = [NSValue valueWithCGPoint:CGPointMake(0.9, 0.9)];
        POPBasicAnimation *opacityDown = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity]; // animate fade to 80% opacity
        opacityDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        opacityDown.toValue = @(0.8);
        
        // Add animation to both left and right cells.
        [beforeCell.layer pop_addAnimation:scaleDown forKey:@"scaleCellDown"];
        [beforeCell.layer pop_addAnimation:opacityDown forKey:@"fadeCellDown"];
        
        [afterCell.layer pop_addAnimation:scaleDown forKey:@"scaleCellDown"];
        [afterCell.layer pop_addAnimation:opacityDown forKey:@"fadeCellDown"];
    });
}
- (void)createDefaultDataSet {
    // Create a default data set with 4 pugs.
    NSArray *names = @[@"Ross", @"Pheobe", @"Chandler", @"Monica"];
    NSManagedObjectContext *context = [appD managedObjectContext];
    NSError *error;
    
    __block int imagesDownloaded = 0;
    for (int i = 0; i <= ([names count] - 1); i++) {
        Pug *pug = [NSEntityDescription insertNewObjectForEntityForName:@"Pug"
                                                 inManagedObjectContext:context];
        pug.name = [names objectAtIndex:i];
        pug.weight = [NSNumber numberWithInt:13 + arc4random() % 7];
        pug.temperament = [temperaments objectAtIndex:0 + arc4random() % [temperaments count]];
        
        // Download image and save to core data to persist.
        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://pugme.herokuapp.com/random"]]];
        requestOperation.responseSerializer = [AFJSONResponseSerializer serializer];
        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *URL = [responseObject objectForKey:@"pug"];
            UIImage *pugImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", URL]]]];
            pug.image = UIImagePNGRepresentation(pugImage);
            NSError *error;
            if (![context save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            }
            
            imagesDownloaded++;
            
            if (imagesDownloaded == [names count]) {
                [HUD dismiss];
                
                // BEGIN: Same animation thingy earlier in scrollViewWillEndDragging: (emphasizes visibly center cell and de-emphasizes (scales down, lowers alpha) of cell to the right.)
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self.pugCollectionView performBatchUpdates:^{
                        [self.pugCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                    } completion:^(BOOL finished) {
                        NSIndexPath *indexPath;
                        if ([self.pugCollectionView indexPathForItemAtPoint:CGPointMake(80 + self.pugCollectionView.contentOffset.x, 250)] != nil) {
                            indexPath = [NSIndexPath indexPathForRow:[self.pugCollectionView indexPathForItemAtPoint:CGPointMake(80 + self.pugCollectionView.contentOffset.x, 250)].row inSection:0];
                            selectedIndexPath = indexPath;
                        }
                        
                        UICollectionViewCell *cell = [self.pugCollectionView cellForItemAtIndexPath:indexPath];
                        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
                        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                        anim.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
                        [cell.layer pop_addAnimation:anim forKey:@"bigger"];
                        POPBasicAnimation *alpha = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
                        alpha.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                        alpha.toValue = @(1.0);
                        [cell.layer pop_addAnimation:alpha forKey:@"fade"];
                        
                        UICollectionViewCell *nextCell = [self.pugCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]];
                        POPBasicAnimation *anim2 = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
                        anim2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                        anim2.toValue = [NSValue valueWithCGPoint:CGPointMake(0.9, 0.9)];
                        [nextCell.layer pop_addAnimation:anim2 forKey:@"bigger"];
                        POPBasicAnimation *alpha2 = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
                        alpha2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                        alpha2.toValue = @(0.8);
                        [nextCell.layer pop_addAnimation:alpha2 forKey:@"fade"];
                    }];
                });
                
                // END
            }
            NSLog(@"images Downloaded %i", imagesDownloaded);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Image error: %@", error);
        }];
        
        [requestOperation start];
        
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
    }
    
    
    // Add data to data model for the collection view datasource to use.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pug"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (Pug *pug in fetchedObjects) {
        [self.pugDataModel addObject:pug];
        NSLog(@"Name: %@", pug.name);
        NSLog(@"Weight: %@", pug.weight);
        NSLog(@"Temperament: %@", pug.temperament);
    }    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    self.pageControl.numberOfPages = self.pugDataModel.count;
    return self.pugDataModel.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PugCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.layer.cornerRadius = 5.0f;
    cell.backgroundColor = [UIColor orangeColor];
    
    // Add actions to feed and walk buttons and make them look prettier.
    cell.feedButton.tag = indexPath.row;
    [cell.feedButton addTarget:self action:@selector(feedPug:) forControlEvents:UIControlEventTouchUpInside];

    cell.walkButton.tag = indexPath.row;
    [cell.walkButton addTarget:self action:@selector(walkPug:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.walkButton.layer.cornerRadius = 3.0f;
    cell.feedButton.layer.cornerRadius = 3.0f;
    
    if (self.pugDataModel.count > 0) {
        
        // Extract data and put it into cells.
        Pug *selectedPug = [self.pugDataModel objectAtIndex:indexPath.row];
        [cell.pugImageView setImage:[UIImage imageWithData:selectedPug.image]];
        cell.nameLabel.text = selectedPug.name;
        cell.weightLabel.text = [NSString stringWithFormat:@"%.2f lbs", selectedPug.weight.doubleValue];
        cell.temperamentLabel.text = selectedPug.temperament;
        
        // have to explicitly state, otherwise when the collectionview reuses the cell, it doesnt realize the real values. probably the worst looking code in this project.
        
        if (selectedPug.weight.doubleValue >= 20) {
            cell.deadView.hidden = YES;
            cell.walkButton.enabled = YES;
            cell.feedButton.enabled = YES;
            cell.walkButton.alpha = 1;
            cell.feedButton.alpha = 1;
            cell.temperamentLabel.text = @"Sedentary. Spends its day watching TV.";
        } else if (selectedPug.weight.doubleValue <= 10) {
            cell.deadView.hidden = NO;
            cell.walkButton.enabled = NO;
            cell.feedButton.enabled = NO;
            cell.walkButton.alpha = 0.5;
            cell.feedButton.alpha = 0.5;
            cell.temperamentLabel.text = @"Perished due to malnutrition.";
        } else {
            cell.deadView.hidden = YES;
            cell.walkButton.enabled = YES;
            cell.feedButton.enabled = YES;
            cell.walkButton.alpha = 1;
            cell.feedButton.alpha = 1;
        }
    }
    
//    [cell addGestureRecognizer:self.longPressRecognizer];
    
    return cell;
}

- (void)feedPug:(id)sender {
    // When presed (fed), pug weight increases by 0.5 pounds.
    
    Pug *selectedPug = [self.pugDataModel objectAtIndex:((UIButton *)sender).tag];
    selectedPug.weight = [NSNumber numberWithDouble:selectedPug.weight.doubleValue + 0.5];
    
    NSManagedObjectContext *context = [appD managedObjectContext];
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    [self.pugCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:((UIButton *)sender).tag inSection:0]]];
}

- (void)walkPug:(id)sender {
    // When pressed (walked), pug weight lowers by 0.25 pounds.
    
    Pug *selectedPug = [self.pugDataModel objectAtIndex:((UIButton *)sender).tag];
    selectedPug.weight = [NSNumber numberWithDouble:selectedPug.weight.doubleValue - 0.25];
    
    NSManagedObjectContext *context = [appD managedObjectContext];
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    [self.pugCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:((UIButton *)sender).tag inSection:0]]];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Custom Segue Transition that opens the "AddPugViewController"
    
    AddPugViewController *detailViewController = segue.destinationViewController;
    
    self.animator = [[ZFModalTransitionAnimator alloc] initWithModalViewController:detailViewController];
    self.animator.dragable = YES;
    self.animator.direction = ZFModalTransitonDirectionBottom;
    
    detailViewController.transitioningDelegate = self.animator;
    detailViewController.modalPresentationStyle = UIModalPresentationCustom;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
