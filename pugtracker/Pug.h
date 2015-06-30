//
//  Pug.h
//  
//
//  Created by Vijay Sridhar on 6/25/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Pug : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) NSString * temperament;
@property (nonatomic, retain) NSData * image;

@end
