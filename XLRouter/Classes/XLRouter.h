//
//  XLRouter.h
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/5/25.
//  Copyright © 2018 XLook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLRouterConst.h"

typedef NSString XLRouterArgumentKey;

@protocol XLRoutableProtocol <NSObject>

/// 调用方传递的参数会被注入到这里
@property (copy, nonatomic, nullable) NSDictionary<XLRouterArgumentKey *, id> *xlr_InjectedArguments;

@required

/**
 获取被路由对象的实例

 @return 被路由对象的实例
 */
+ (__kindof UIViewController<XLRoutableProtocol> *_Nonnull)xlr_Instance;

/**
 被路由对象的 alias name，必须提供
 
 @return alias name
 */
+ (NSString *_Nonnull)xlr_AliasName;

@optional

/**
 被路由对象的 scope name，默认值为 default

 @return scope name
 */
+ (NSString *_Nullable)xlr_ScopeName;

/**
 被路由的对象接受的参数类型信息，外部传入的参数最终会被放在 xlr_InjectedArguments 里

 @return NSDictionary
 */
+ (NSDictionary<XLRouterArgumentKey *, id> *_Nullable)xlr_AcceptedArgumentType;

/**
 被路由的对象必须的参数类型，参数保存在 xlr_InjectedArguments 里

 @return NSArray
 */
+ (NSArray<XLRouterArgumentKey *> *_Nullable)xlr_RequiredArgumentKeys;

@end

// Router URL 格式：xlook://viewcontroller.router.component/[-scope default]/[-alias User]

@interface XLRouter : NSObject

/**
 获取单例对象

 @return 单例对象
 */
+ (instancetype _Nonnull)sharedInstance;

/**
 手动注册一个可以被路由的类，暂时只能手动注册，之后会改成自动发现的
 
 @param routableClass 实现 XLRoutableProtocol 协议的类
 */
- (void)registerRoutable:(Class <XLRoutableProtocol> _Nonnull)routableClass;

/**
 处理 URL，必须在 - [AppDelegate openURL:options:] 内调用
 
 @param URL - [AppDelegate openURL:options:] 中的 URL
 @param options - [AppDelegate openURL:options:] 中的 options
 @return 是否可以处理 URL
 */
- (BOOL)handleURL:(NSURL *_Nonnull)URL options:(NSDictionary *_Nonnull)options;

/**
 保存 options 并获取对应的 token，之后再拿这个 options 必须给定 token
 
 @param options 要保存的 options
 @return 相应的 token
 */
- (NSString *_Nonnull)saveURLOptions:(NSDictionary<XLRouterOptionKey *, id> *_Nonnull)options;

@end
