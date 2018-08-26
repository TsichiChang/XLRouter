//
//  NSURL+QueryItem.m
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/5/29.
//  Copyright © 2018 XLook. All rights reserved.
//

#import "NSURL+QueryItem.h"

@implementation NSURL (QueryItem)

/**
 Split URL's query to dictionary.
 
 a=1&b=2&c=3&  ==>  {
 a : 1,
 b : 2,
 C : 3
 }
 
 @return A dictionary contains query items
 */
- (NSDictionary *)queryItems {
    
    NSMutableDictionary *queryItems = [NSMutableDictionary dictionaryWithCapacity:10];
    
    for (NSString *queryItem in [self.query componentsSeparatedByString:@"&"]) {
        
        NSArray *elts = [queryItem componentsSeparatedByString:@"="];
        
        if([elts count] == 2) {
            [queryItems setObject:[elts lastObject] forKey:[elts firstObject]];
        }
    }
    return queryItems;
}

@end
