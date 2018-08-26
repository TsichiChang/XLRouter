//
//  NSURL+QueryItem.h
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/5/29.
//  Copyright © 2018 XLook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (QueryItem)

/**
 Split URL's query to dictionary.
 
 a=1&b=2&c=3&  ==>  {
                        a : 1,
                        b : 2,
                        C : 3
                    }

 @return A dictionary contains query items
 */
- (NSDictionary *)queryItems;

@end
