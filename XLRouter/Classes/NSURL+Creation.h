//
//  NSURL+Creation.h
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/6/4.
//  Copyright © 2018 XLook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLRouterConst.h"

@interface NSURL (Creation)

/**
 创建 default scope 下的 Router URL
 
 @param aliasName 由 XLRoutableProtocol 协议中 + xlr_AliasName 方法定义
 @param optionsBlock 在 Block 中添加需要的参数，支持的参数可以参考 XLRouterConst.h 中定义的 XLRouterOption
 @return URL 对象，使用 - [UIApplication openURL] 打开
 */
+ (instancetype _Nullable)routerURLWithAliasName:(NSString *_Nonnull)aliasName
                          optionsBlock:(void(^ _Nullable)(NSMutableDictionary *_Nonnull options))optionsBlock;

/**
 创建 Router URL

 @param aliasName 由 XLRoutableProtocol 协议中 + xlr_AliasName 方法定义
 @param scopeName 由 XLRoutableProtocol 协议中 + xlr_ScopeName 方法定义
 @param optionsBlock 在 Block 中添加需要的参数，支持的参数可以参考 XLRouterConst.h 中定义的 XLRouterOption
 @return URL 对象，使用 - [UIApplication openURL] 打开
 */
+ (instancetype _Nullable)routerURLWithAliasName:(NSString *_Nonnull)aliasName
                             scopeName:(NSString *_Nonnull)scopeName
                          optionsBlock:(void(^ _Nullable)(NSMutableDictionary *_Nonnull options))optionsBlock;

@end
