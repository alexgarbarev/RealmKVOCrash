////////////////////////////////////////////////////////////////////////////////
//
//  APPSQUICK.LY
//  Copyright 2016 AppsQuick.ly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of AppsQuick.ly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "RLMObject.h"

@protocol RLMInt;


@interface Person : RLMObject

@property (nonatomic) int identifier;
@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSNumber<RLMInt> *age;

@end