//
//  NSString+Random.m
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/6/1.
//  Copyright © 2018 XLook. All rights reserved.
//

#import "NSString+Random.h"

@implementation NSString (Random)

+ (NSString *)randomStringForLength:(int)length {
    NSMutableString *string = [NSMutableString stringWithCapacity:length];
    for (int i = 0; i < length; i++) {
        [string appendFormat:@"%C", (unichar)('a' + arc4random_uniform(26))];
    }
    return string;
}

@end
