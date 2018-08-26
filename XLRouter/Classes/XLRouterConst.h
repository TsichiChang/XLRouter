//
//  XLRouterConst.h
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/6/4.
//  Copyright © 2018 XLook. All rights reserved.
//

#ifndef XLRouterConst_h
#define XLRouterConst_h

#pragma mark -
#pragma mark XLRouterURL Define

typedef NSString XLRouterURL;
static XLRouterURL * const XLRouterURLScheme = @"xlook";
static XLRouterURL * const XLRouterURLHost = @"viewcontroller.router.component";

static XLRouterURL * const XLRouterURLControllerBaseURL = @"xlook://viewcontroller.router.component/";
static XLRouterURL * const XLRouterURLQueryToken = @"token";
static XLRouterURL * const XLRouterURLScopeDefault = @"default";


#pragma mark -
#pragma mark XLRouterOption Define

typedef NSString XLRouterOptionKey;
static XLRouterOptionKey * const XLRouterOptionControllerShowTypeKey = @"XLRouterOptionControllerShowType";
static XLRouterOptionKey * const XLRouterOptionControllerAnimatedKey = @"XLRouterOptionControllerAnimated";
static XLRouterOptionKey * const XLRouterOptionControllerCompletionKey = @"XLRouterOptionControllerCompletion";
static XLRouterOptionKey * const XLRouterOptionControllerArgumentkey = @"XLRouterOptionControllerArgument";

typedef enum : NSUInteger {
    XLRouterOptionControllerShowTypePresent, // default
    XLRouterOptionControllerShowTypeNavigate
} XLRouterOptionControllerShowType;

typedef enum : NSUInteger {
    XLRouterOptionControllerAnimatedNO,
    XLRouterOptionControllerAnimatedYES // default
} XLRouterOptionControllerAnimated;



#endif /* XLRouterConst_h */
