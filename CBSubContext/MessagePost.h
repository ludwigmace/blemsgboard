//
//  MessagePost.h
//  SubContext
//
//  Created by Mason Schoolfield and Robert Sandoval on 4/27/14.
//  Copyright (c) 2014 UT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MessagePost : NSManagedObject

@property (nonatomic, retain) NSString * messageText;
@property (nonatomic, retain) NSNumber * counter;
@property (nonatomic, retain) NSDate * ts;
@property (nonatomic, retain) NSString * sContext;
@property (nonatomic, retain) NSString * author;

@end
