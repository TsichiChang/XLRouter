//
//  NSString+Random.h
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/6/1.
//  Copyright © 2018 XLook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Random)

/**
 生成给定长度的随机字符串

 @param length 长度
 @return 随机字符串
 */
+ (NSString *)randomStringForLength:(int)length;

@end
