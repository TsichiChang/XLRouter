//
//  NSURL+Creation.m
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/6/4.
//  Copyright © 2018 XLook. All rights reserved.
//

#import "NSURL+Creation.h"
#import "XLRouter.h"

@implementation NSURL (Creation)

+ (instancetype)routerURLWithAliasName:(NSString *_Nonnull)aliasName
                          optionsBlock:(void(^ _Nullable)(NSMutableDictionary *options))optionsBlock {
    return [NSURL routerURLWithAliasName:aliasName scopeName:XLRouterURLScopeDefault optionsBlock:optionsBlock];
}

+ (instancetype)routerURLWithAliasName:(NSString *_Nonnull)aliasName
                             scopeName:(NSString *_Nonnull)scopeName
                          optionsBlock:(void(^ _Nullable)(NSMutableDictionary *options))optionsBlock {
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:10];
    
    // 添加默认值
    [options setObject:@(YES) forKey:XLRouterOptionControllerAnimatedKey];
    [options setObject:@(XLRouterOptionControllerShowTypePresent) forKey:XLRouterOptionControllerShowTypeKey];
    
    if (optionsBlock) {
        optionsBlock(options);
    }
    
    NSString *token = [[XLRouter sharedInstance] saveURLOptions:options];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:XLRouterURLControllerBaseURL];
    components.path = [NSString stringWithFormat:@"/%@/%@", scopeName, aliasName];
    components.query = [NSString stringWithFormat:@"%@=%@", XLRouterURLQueryToken, token];
    return [components URL];
}

@end
