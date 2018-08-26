//
//  XLRouter.m
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/5/25.
//  Copyright © 2018 XLook. All rights reserved.
//

#import "XLRouter.h"
#import "NSURL+QueryItem.h"
#import "NSString+Random.h"
#import <objc/runtime.h>

static NSString * const XLRouteTableKeyClassName = @"XLRouteTableKeyClassName";
static NSString * const XLRouteTableKeyAcceptedArgumentsType = @"XLRouteTableAcceptedArgumentsType";
static NSString * const XLRouteTableKeyRequiredArgumentsKeys = @"XLRouteTableRequiredArgumentsKeys";

@interface XLRouteOperation : NSObject
/// 域，默认为 default 域
@property (copy, nonatomic, nonnull) NSDictionary *scope;
/// 别名，被路由的对象的一些参数
@property (copy, nonatomic, nonnull) NSDictionary *alias;
/// 被路由的对象 class
@property (strong, nonatomic, nonnull) Class class;
/// controller 打开的方式
@property (assign, nonatomic) XLRouterOptionControllerShowType type;
/// 打开 URL 时的参数
@property (copy, nonatomic, nullable) NSDictionary<XLRouterOptionKey *, id> *options;
@end

@implementation XLRouteOperation
@end


@interface XLRouter ()
/// 路由表
@property (copy, nonatomic, nonnull) NSMutableDictionary *routeTable;
/// 保存 - [saveURLOptions:] 储存的 options
@property (copy, nonatomic, nonnull) NSMutableDictionary *URLOptionsStore;
@end

@implementation XLRouter

#pragma mark -
#pragma mark Lifecycle

+ (instancetype)sharedInstance {
    static XLRouter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XLRouter alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self registerMemoryWarningObserver];
    }
    return self;
}

- (void)dealloc {
    [self removeMemoryWarningObserver];
    // TODO: 持久化 self.routeTable
}

#pragma mark -
#pragma mark Notification Observer

- (void)registerMemoryWarningObserver {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveMemoryWarning)
                                               name:UIApplicationDidReceiveMemoryWarningNotification
                                             object:nil];
}

- (void)removeMemoryWarningObserver {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidReceiveMemoryWarningNotification
                                                object:nil];
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // TODO: release cache
    // 暂时没有实现，清除缓存的策略暂时是这么考虑的：
    // 1. 把 scope 和 alias 全部按照 LRU 算法排序
    // 2. 需要清除的时候，每次清除 一半 scope 和 一半 alias
    // 3. 如果 scope 只有一个，那么就只清除一半 alias
    // 感觉这个释放不出太多的空间。。。。。。
    //
    // when and how to clear sharedMemory?
}


#pragma mark -
#pragma mark Find in route table

/**
 根据 scope 名字取对应的字典

 @param scopeName scope 名字
 @return scope 字典
 */
- (NSMutableDictionary *)scopeByName:(NSString *)scopeName {
    
    NSMutableDictionary *scope = self.routeTable[scopeName];
    
    if (!scope) {
        scope = [NSMutableDictionary dictionaryWithCapacity:50];
        self.routeTable[scopeName] = scope;
    }
    return scope;
}

/**
 根据 alias 和 scope 名字取对应的字典，alias 是保存在特定的 scope 中的

 @param aliasName alias 名字
 @param scopeName scope 名字
 @return alias 字典
 */
- (NSMutableDictionary *)aliasByName:(NSString *)aliasName
                             inScope:(NSString *)scopeName {
    
    NSMutableDictionary *scope = [self scopeByName:scopeName];
    NSMutableDictionary *alias = scope[aliasName];
    
    if (!alias) {
        alias = [NSMutableDictionary dictionaryWithCapacity:10];
        scope[aliasName] = alias;
    }
    return alias;
}

#pragma mark -
#pragma mark Save and Pop Arguments

/**
 保存 URL Options 并获取对应的 token，之后再拿这个 URL Options 必须给定 token
 注意：这里会对 URL Options 强引用，所以必须通过 - [popURLOptionsForToken:] 取走，否则会内存泄漏

 @param options 要保存的 URL Options
 @return 相应的 token
 */
- (NSString *)saveURLOptions:(NSDictionary<XLRouterArgumentKey *,id> *)options {
    
    int tokenLength = 16;
    int retryCount = 0;
    
    NSString *token = [NSString randomStringForLength:tokenLength];
    
    while (retryCount < 4) {
        if ([self.URLOptionsStore.allKeys containsObject:token]) {
            break;
        }
        token = [NSString randomStringForLength:tokenLength];
        retryCount++;
    }
    
    [self.URLOptionsStore setObject:options forKey:token];
    
    return token;
}

/**
 根据 token 取出对应的 arguments，如果不存在会返回 nil

 @param token 保存 argument 时拿到的 token
 @return URL Options
 */
- (NSDictionary *_Nullable)popURLOptionsForToken:(NSString *)token {
    
    NSDictionary *options = nil;
    
    if ([self.URLOptionsStore.allKeys containsObject:token]) {
        options = self.URLOptionsStore[token];
        [self.URLOptionsStore removeObjectForKey:token];
    }
    
    return options;
}

#pragma mark -
#pragma mark Public Methods

/**
 处理 URL，必须在 - [AppDelegate openURL:options:] 内调用

 @param URL - [AppDelegate openURL:options:] 中的 URL
 @param options - [AppDelegate openURL:options:] 中的 options
 @return 是否可以处理 URL
 */
- (BOOL)handleURL:(NSURL *)URL options:(NSDictionary *)options {
    // 1. 只能在主线程调用
    // 2. 只能同 App 调用（sourceApplication）
    // 3. URL scheme 和 host 匹配
    if (![self validateThread] ||
        ![self validateSource:options] ||
        ![self validateURL:URL]) {
        return NO;
    }
    
    XLRouteOperation *operation = [self operationFromURL:URL];
    
    if (operation) {
        [self handleOperation:operation];
    }
    
    return YES;
}

/**
 手动注册一个可以被路由的类

 @param routableClass 实现 XLRoutableProtocol 协议的类
 */
- (void)registerRoutable:(Class<XLRoutableProtocol>)routableClass {
    
    NSString *scope = XLRouterURLScopeDefault;
    
    if ([routableClass respondsToSelector:@selector(xlr_ScopeName)]) {
        scope = [routableClass xlr_ScopeName];
    }
    
    [self addArgumentsPropertyForClass:routableClass];
    
    NSString *aliasName = [routableClass xlr_AliasName];
    
    NSMutableDictionary *alias = [self aliasByName:aliasName inScope:scope];
    
    alias[XLRouteTableKeyClassName] = routableClass;
    
    if ([routableClass respondsToSelector:@selector(xlr_AcceptedArgumentType)]) {
        alias[XLRouteTableKeyAcceptedArgumentsType] = [routableClass xlr_AcceptedArgumentType];
    }
    if ([routableClass respondsToSelector:@selector(xlr_RequiredArgumentKeys)]) {
        alias[XLRouteTableKeyRequiredArgumentsKeys] = [routableClass xlr_RequiredArgumentKeys];
    }
}

#pragma mark -
#pragma mark Private Methods

/**
 处理从 URL 转换过来的 operation

 @param operation operation 对象
 */
- (void)handleOperation:(XLRouteOperation *)operation {
    // 把 Controller 展示出来的 Controller
    UINavigationController *showingController = [self showingViewControllerByShowMethod:operation.type];
    // 被展示的 Controller
    UIViewController<XLRoutableProtocol> *shownController = nil;
    
    if ([operation.class respondsToSelector:@selector(xlr_Instance)]) {
        shownController = [(id<XLRoutableProtocol>)operation.class xlr_Instance];
    } else {
        return; // 因为不确定使用 class_createInstance(Class, site_t) 创建出来什么东西，所以还是直接返回
    }
    
    [shownController setXlr_InjectedArguments:operation.options[XLRouterOptionControllerArgumentkey]];
    
    NSNumber *animated = operation.options[XLRouterOptionControllerAnimatedKey];
    
    if (operation.type == XLRouterOptionControllerShowTypeNavigate) {
        [showingController pushViewController:shownController animated:animated.boolValue];
    } else if (operation.type == XLRouterOptionControllerShowTypePresent){
        void(^completion)(void) = operation.options[XLRouterOptionControllerCompletionKey];
        [showingController presentViewController:shownController animated:animated.boolValue completion:completion];
    }
}

/**
 根据展示 ViewController 的方式获取 showing controller，这个 showing controller 是用来 push/present 被展示的 controller 的

 @param method 展示 Controller 的方式
 @return 获取到的 showing controller
 */
- (__kindof UIViewController *_Nullable)showingViewControllerByShowMethod:(XLRouterOptionControllerShowType)method {
    
#define CLASS_OF_OBJECT(object) [object class]
#define IS_SAME_KIND(object1, object2) [object1 isKindOfClass:CLASS_OF_OBJECT(object2)]
    
    __kindof UIViewController *showingController = nil;
    
    UIViewController *root = UIApplication.sharedApplication.keyWindow.rootViewController;
    
    if (IS_SAME_KIND(root, UITabBarController)) {
        showingController = ((UITabBarController *)root).selectedViewController;
    } else {
        showingController = root;
    }
    
    // 如果是 navigate 方式导航的话，要求 showing controller 必须是 UINavigationController
    if (method == XLRouterOptionControllerShowTypeNavigate &&
        !IS_SAME_KIND(showingController, UINavigationController)) {
        showingController = nil;
    }
    
    return showingController;
}

/**
 把 URL 解析成 XLRouterOpertion 对象，中间会做一些 URL、参数验证的工作

 @param URL 外面传递的 URL
 @return XLRouterOperation 对象，如果解析失败会返回 nil
 */
- (XLRouteOperation *_Nullable)operationFromURL:(NSURL *_Nonnull)URL {
    
    NSArray * pathComponents = [self trimmedPathComponentFromURL:URL];
    
    // pathComponents 至少应该有 2 个：scope、name
    if (!pathComponents || pathComponents.count < 2) {
        NSAssert(NO, @"URL is broken");
        return nil;
    }
    
    NSMutableDictionary *scope = self.routeTable[pathComponents[0]];
    if (!scope) {
        NSAssert(NO, @"Scope defined in URL cannot be found.");
        return nil;
    }
    
    NSMutableDictionary *alias = scope[pathComponents[1]];
    if (!alias) {
        NSAssert(NO, @"Alias defined in URL cannot be found.");
        return nil;
    }
    
    NSDictionary *URLOptions = [self popURLOptionsForToken:URL.queryItems[XLRouterURLQueryToken]];
    
    XLRouterOptionControllerShowType showType = [URLOptions[XLRouterOptionControllerShowTypeKey] unsignedIntegerValue];
    
    if (showType != XLRouterOptionControllerShowTypeNavigate &&
        showType != XLRouterOptionControllerShowTypePresent) {
        NSAssert(NO, @"Unsupported route method.");
        return nil;
    }
    
    NSDictionary *arguments = URLOptions[XLRouterOptionControllerArgumentkey];
    NSArray<XLRouterArgumentKey *> *requiredArgumentKeys = [self requiredArgumentKeysFromAlias:alias];
    NSDictionary<XLRouterArgumentKey *, id> *acceptedArgumentType = [self acceptedArgumentTypeFromAlias:alias];
    
    // =========================================================================== //
    //                        Instruction of following code                        //
    //                                                                             //
    // 对调用方传入的参数做检查，首先调用方必须传递了全部的必须参数，如果没有传递则不能路由        //
    // 其次，调用方传递的全部参数，参数类型必须和被调用方要求的一致，如果参数类型不对也不能路由     //
    // 最后，调用方不允许传入的未知参数，即被调方未声明在 +xlp_AcceptedArguments 方法中的参数  //
    // =========================================================================== //
    
    /**
     1. arguments 空，requiredArgumentKeys 非空 —— 参数不全，少传了
     2. arguments 非空，acceptedArgumentType 空 —— 参数有误，多传了
     3. arguments 非空，acceptedArgumentType 非空，arguments 个数比 acceptedArgumentType 个数多 —— 参数有误，多传了
     4. 三者都非空，requiredArgumentKeys 个数比 arguments 个数多 —— 参数不全，少传了
     
     以上四种情况都是代码写错了，好好检查检查，看不明白画一个真值表就知道了
     **/
    if (// arguments 空，requiredArgumentKeys 非空 —— 参数不全，少传了
        (!arguments && requiredArgumentKeys) ||
        // arguments 非空，acceptedArgumentType 空 —— 参数有误，多传了
        (arguments && !acceptedArgumentType) ||
        // arguments 非空，acceptedArgumentType 非空，arguments 个数比 acceptedArgumentType 个数多 —— 参数有误，多传了
        (!arguments && !acceptedArgumentType && arguments.allKeys.count > acceptedArgumentType.allKeys.count) ||
        // 三者都非空，requiredArgumentKeys 个数比 arguments 个数多 —— 参数不全，少传了
        (!arguments && !acceptedArgumentType && !requiredArgumentKeys && requiredArgumentKeys.count > arguments.count)) {
        NSAssert(NO, @"Wrong arguments, check it !");
        return nil;
    }
    
    if (arguments) {
        
        // 检查 + requiredArgumentKeys 里面定义的参数是否正确传递
        BOOL isRequiredArgumentsCorrect = YES;
        
        if (requiredArgumentKeys) {
            isRequiredArgumentsCorrect = [self validateInputArguments:arguments
                                             withAcceptedArgumentType:acceptedArgumentType
                                             withRequiredArgumentKeys:requiredArgumentKeys];
        }
        
        // 检查除了 + requiredArgumentKeys 里面定义的参数之外，其他参数是否正确传递
        NSMutableArray *remainingArgumentKeys = [arguments.allKeys mutableCopy];
        
        if (requiredArgumentKeys) {
            [remainingArgumentKeys removeObjectsInArray:requiredArgumentKeys];
        }

        BOOL isRemainingArgumentsCorrect = [self validateInputArguments:arguments
                                               withAcceptedArgumentType:acceptedArgumentType
                                                               withKeys:remainingArgumentKeys];
        
        // 如果有任何一个参数传递不正确，那么都无法路由
        if (!isRequiredArgumentsCorrect || !isRemainingArgumentsCorrect) {
            return nil;
        }
    }
    
    XLRouteOperation *operation = [[XLRouteOperation alloc] init];
    operation.type = showType;
    operation.scope = scope;
    operation.alias = alias;
    operation.class = alias[XLRouteTableKeyClassName];
    operation.options = URLOptions;
    
    return operation;
}

#pragma mark -
#pragma mark Complete Routable Class

/**
 Getter 方法

 @param self OC 中方法的隐藏参数 self
 @param _cmd OC 中方法的隐藏参数 sel
 @return Get 的属性
 */
NSDictionary<XLRouterArgumentKey *, id> * xlr_InjectedArguments(id self, SEL _cmd) {
    return objc_getAssociatedObject(self, _cmd);
}

/**
 Setter 方法

 @param self OC 中方法的隐藏参数 self
 @param _cmd OC 中方法的隐藏参数 sel
 @param xlr_InjectedArguments Set 的属性
 */
void setXlr_InjectedArguments(id self, SEL _cmd, NSDictionary<XLRouterArgumentKey *, id> *xlr_InjectedArguments) {
    objc_setAssociatedObject(self, @selector(xlr_InjectedArguments), xlr_InjectedArguments, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 给被路由的类的属性 xlr_InjectedArguments 增加 Getter 和 Setter 方法
 
 xlr_InjectedArguments 属性是声明在 @property 中的，所以如果不增加 getter 和 setter 在运行时调用会报错
 增加的方法可以手动 @synthesize 合成或者是写 setter 和 getter，这两种方案都不够方便，所以最后采用 Runtime 的方案
 
 @param class 被路由的 class 对象
 */
- (void)addArgumentsPropertyForClass:(Class _Nullable)class {
    
    if (![class instancesRespondToSelector:@selector(setXlr_InjectedArguments:)]) {
        class_addMethod(class, @selector(setXlr_InjectedArguments:), (IMP)setXlr_InjectedArguments, "v@:@");
    }
    
    if (![class instancesRespondToSelector:@selector(xlr_InjectedArguments)]) {
        class_addMethod(class, @selector(xlr_InjectedArguments), (IMP)xlr_InjectedArguments, "@@:");
    }
}

#pragma mark -
#pragma mark Get something from given things...

/**
 从 URL 从提取 path 数组，并处理掉可能存在的第一个 '/' 元素
 
 @param URL 待提取的 URL
 @return pathComponent 数组
 */
- (NSArray *_Nullable)trimmedPathComponentFromURL:(NSURL *_Nonnull)URL {
    
    if (!URL.pathComponents) {
        return nil;
    }
    
    NSArray *pathComponent = nil;
    // [NSURL pathComponent] 返回的数组中第一个元素可能是 "/"，所以要修剪（trim）
    if ([URL.pathComponents[0] isEqualToString:@"/"]) {
        pathComponent = [URL.pathComponents subarrayWithRange:NSMakeRange(1, URL.pathComponents.count - 1)];
    } else {
        pathComponent = [URL.pathComponents copy];
    }
    return pathComponent;
}

/**
 获取 alias 的 requiredArgumentKeys 信息
 
 首先从 routeTable 里面取，如果没有的话调用 + xlr_RequiredArgumentKeys 方法获取
 如果调用方法也获取不到的话，那么就认为是没有 requiredArgumentKeys 信息
 如果获取到的 Array.count = 0 也认为是没有  requiredArgumentKeys 信息
 
 @param alias 被获取的 alias
 @return requiredArgumentKeys 信息，可能为空
 */
- (NSArray<XLRouterArgumentKey *> *_Nullable)requiredArgumentKeysFromAlias:(NSMutableDictionary *)alias {
    
    Class<XLRoutableProtocol> class = alias[XLRouteTableKeyClassName];
    NSArray<XLRouterArgumentKey *> *result = alias[XLRouteTableKeyRequiredArgumentsKeys];
    // TODO: 考虑去除这个检查，直接从 routeTable 中读取，现在在注册的时候已经添加了
    if (!result && [class respondsToSelector:@selector(xlr_RequiredArgumentKeys)]) {
        
        result = [class xlr_RequiredArgumentKeys];
        
        if (!result || !result.count) {
            result = nil;
        } else {
            alias[XLRouteTableKeyRequiredArgumentsKeys] = result;
        }
    }
    return result;
}

/**
 获取 alias 的 acceptedArgumentType 信息
 
 首先从 routeTable 里面取，如果没有的话调用 + xlr_AcceptedArgumentType 方法获取
 如果调用方法也获取不到的话，那么就认为是没有 acceptedArgumentType 信息
 如果获取到的 Dictionary.allKeys.count = 0 也认为是没有  acceptedArgumentType 信息

 @param alias 被获取的 alias
 @return acceptedArgumentType 信息，可能为空
 */
- (NSDictionary<XLRouterArgumentKey *, id> *_Nullable)acceptedArgumentTypeFromAlias:(NSMutableDictionary *)alias {
    
    Class<XLRoutableProtocol> class = alias[XLRouteTableKeyClassName];
    NSDictionary<XLRouterArgumentKey *, id> *result = alias[XLRouteTableKeyAcceptedArgumentsType];
    // TODO: 考虑去除这个检查，直接从 routeTable 中读取，现在在注册的时候已经添加了
    if (!result && [class respondsToSelector:@selector(xlr_AcceptedArgumentType)]) {
        
        result = [class xlr_AcceptedArgumentType];
        
        if (!result || !result.count) {
            result = nil;
        } else {
            alias[XLRouteTableKeyAcceptedArgumentsType] = result;
        }
    }
    return result;
}

#pragma Validation

/**
 验证传入的 URL 的 scheme 和 host 是否符合 RouterURL

 @param URL 待验证的 URL
 @return 是否可以被处理
 */
- (BOOL)validateURL:(NSURL *)URL {
    // scheme 或 host 不对的话，就不处理了
    if (![URL.scheme isEqualToString:XLRouterURLScheme] ||
        ![URL.host isEqualToString:XLRouterURLHost]) {
        return NO;
    }
    
    return YES;
}

/**
 验证是否在主线程上调用

 @return 是否在主线程上调用
 */
- (BOOL)validateThread {
    if (![[NSThread currentThread] isMainThread]) {
        NSAssert(NO, @"Router should be called on Main Thread, current thread is %@", NSThread.currentThread.name);
        return NO;
    } else {
        return YES;
    }
}

/**
 验证调用 URL 的 App 是否是本 App

 @param URLOptions 从 - application:openURL:options: 处获得
 @return 是否是本 App 调用
 */
- (BOOL)validateSource:(NSDictionary *)URLOptions {
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:URLOptions[UIApplicationOpenURLOptionsSourceApplicationKey]]) {
        return YES;
    }
    return NO;
}

/**
 判断两个对象是否是同一个类型，如果 object1 是 object2 的子类，也认为是同一类型

 @param object1 待验证的对象1
 @param object2 待验证的对象2
 @return 是否是同一个类型
 */
#define VALIDATE_IF_OBJECT_MATCHED(object1, object2) \
    do { \
        if (![object1 isEqual:object2] && \
            ![object1 isKindOfClass:[object2 class]]) { \
            NSAssert(NO, @"%@ is not matched with given object %@", object1, object2); \
            return NO; \
        } \
    } while(0)

/**
 判断传入的 object 是否是空

 @param object 待验证的 object
 @return 是否为空
 */
#define VALIDATE_IF_OBJECT_IS_NULL(object) \
    do { \
        if (!object) { \
            NSAssert(NO, @"Missing object info: %@ in acceptedArgumentType", object); \
            return NO; \
        } \
    } while(0)

/**
 验证 requiredArgumentKeys 里面定义的参数是否都在 inputArguments 传递，而且参数类型是否符合要求
 
 这个方法实际是为了隐藏 index 这个参数，看着好看一点
 
 @param inputArguments 待验证的参数
 @param acceptedArgumentType 可以接受的参数的类型信息
 @param requiredArgumentKeys 必须传递的参数
 @return 是否通过验证， YES：通过验证。NO：不合法参数
 */
- (BOOL)validateInputArguments:(NSDictionary<XLRouterArgumentKey *, id> *_Nonnull)inputArguments
      withAcceptedArgumentType:(NSDictionary<XLRouterArgumentKey *, id> *_Nonnull)acceptedArgumentType
      withRequiredArgumentKeys:(NSArray<XLRouterArgumentKey *> *_Nullable)requiredArgumentKeys {
    return [self validateInputArguments:inputArguments
               withAcceptedArgumentType:acceptedArgumentType
               withRequiredArgumentKeys:requiredArgumentKeys
                              withIndex:0];
}

/**
 验证 requiredArgumentKeys 里面定义的参数是否都在 inputArguments 传递，而且参数类型是否符合要求
 
 @param inputArguments 待验证的参数
 @param acceptedArgumentType 可以接受的参数的类型信息
 @param requiredArgumentKeys 必须传递的参数
 @param index 索引，指示当前现在验证到了 requiredArgumentKeys 里面的第几个 key，为了实现尾递归优化（Tail Recursion Optimization）
 @return 是否通过验证， YES：通过验证。NO：不合法参数
 */
- (BOOL)validateInputArguments:(NSDictionary<XLRouterArgumentKey *, id> *_Nonnull)inputArguments
      withAcceptedArgumentType:(NSDictionary<XLRouterArgumentKey *, id> *_Nonnull)acceptedArgumentType
      withRequiredArgumentKeys:(NSArray<XLRouterArgumentKey *> *_Nullable)requiredArgumentKeys
                     withIndex:(NSInteger)index {
    
    if (!requiredArgumentKeys || requiredArgumentKeys.count == index) {
        return YES;
    }
    
    XLRouterArgumentKey *argumentKey = requiredArgumentKeys[index];
    
    if (![inputArguments.allKeys containsObject:argumentKey]) {
        NSAssert(NO, @"Missing required argument: %@", argumentKey);
        return NO;
    }
    
    id acceptedArgument = acceptedArgumentType[argumentKey];
    VALIDATE_IF_OBJECT_IS_NULL(acceptedArgument);
    id inputArgument = inputArguments[argumentKey];
    VALIDATE_IF_OBJECT_MATCHED(inputArgument, acceptedArgument);
    
    index++;
    
    return [self validateInputArguments:inputArguments
               withAcceptedArgumentType:acceptedArgumentType
               withRequiredArgumentKeys:requiredArgumentKeys
                              withIndex:index];
}

/**
 验证 inputArguments 中除了 requiredArgumentKeys 定义之外的参数是否存在于 acceptedArgumentType 中，且类型是否一致
 
 这个方法实际是为了隐藏 iteratorKeys 这个参数，看着好看一点

 @param inputArguments 待验证的参数，上面使用的时候，实际上是已经去除了 requiredKeys 之后的剩余参数
 @param acceptedArgumentType 可以接受的参数的类型信息
 @return 是否通过验证， YES：通过验证。NO：不合法参数
 */
- (BOOL)validateInputArguments:(NSDictionary<XLRouterArgumentKey *, id> *)inputArguments
      withAcceptedArgumentType:(NSDictionary<XLRouterArgumentKey *, id> *)acceptedArgumentType {
    return [self validateInputArguments:inputArguments
               withAcceptedArgumentType:acceptedArgumentType
                               withKeys:[inputArguments.allKeys mutableCopy]];
}

/**
 验证 inputArguments 中除了 requiredArgumentKeys 定义之外的参数是否存在于 acceptedArgumentType 中，且类型是否一致

 @param inputArguments 待验证的参数，上面使用的时候，实际上是已经去除了 requiredKeys 之后的剩余参数
 @param acceptedArgumentType 可以接受的参数的类型信息
 @param iteratorKeys 待验证的 key，为了实现尾递归优化（Tail Recursion Optimization），所以传了这个参数
 @return 是否通过验证， YES：通过验证。NO：不合法参数
 */
- (BOOL)validateInputArguments:(NSDictionary<XLRouterArgumentKey *, id> *)inputArguments
      withAcceptedArgumentType:(NSDictionary<XLRouterArgumentKey *, id> *)acceptedArgumentType
                      withKeys:(NSMutableArray<XLRouterArgumentKey *> *)iteratorKeys {
    // 每次都会移除一个被验证过的 key，如果最后没有 key 了，递归结束
    if (!iteratorKeys || !iteratorKeys.count) {
        return YES;
    }
    
    XLRouterArgumentKey *argumentKey = [iteratorKeys firstObject];
    
    id acceptedArgument = acceptedArgumentType[argumentKey];
    VALIDATE_IF_OBJECT_IS_NULL(acceptedArgument);
    id inputArgument = inputArguments[argumentKey];
    VALIDATE_IF_OBJECT_MATCHED(inputArgument, acceptedArgument);
    
    [iteratorKeys removeObject:argumentKey];
    
    return [self validateInputArguments:inputArguments
               withAcceptedArgumentType:acceptedArgumentType
                               withKeys:iteratorKeys];
}

#pragma mark -
#pragma mark Getter & Setter

/**
 routeTable Getter

 @return routeTable
 */
- (NSMutableDictionary *)routeTable {
    if (!_routeTable) {
        _routeTable = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return _routeTable;
}

/**
 sharedMemory Getter

 @return sharedMemory
 */
- (NSMutableDictionary<NSString *,id> *)URLOptionsStore {
    if (!_URLOptionsStore) {
        _URLOptionsStore = [NSMutableDictionary dictionaryWithCapacity:50];
    }
    return _URLOptionsStore;
}

@end
