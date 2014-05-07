//
//  DataToSend.h
//  SubContext
//
//  Created by Mason Schoolfield and Robert Sandoval on 4/30/14.
//  Copyright (c) 2014 UT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataToSend : NSObject

@property NSData *payload;
@property NSNumber *sendIndex;
@property NSString *eomStatus;

@end
