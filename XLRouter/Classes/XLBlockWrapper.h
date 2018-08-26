//
//  XLBlockPlaceHolder.h
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/6/5.
//  Copyright © 2018 XLook. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 此类用来包装一个 Block 代码块，并支持用 isEqual: 做 Block 的方法签名检查
 如果两个 Block 的返回值和输入参数完全一致，那么认为这两个 Block 是相等的
 
 注意：这里有个问题就是如果 Block 内部的代码不一样，也会被认为是相等。
 */
@interface XLBlockWrapper : NSObject

/**
 包装 Block，方便传递或者是做参数校验
 
 @param block Block
 */
- (void)wrapBlock:(id)block;

/**
 获得内部解包的 Block
 
 @return Block
 */
- (id)unwrapBlock;

@end
