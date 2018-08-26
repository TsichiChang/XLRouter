//
//  XLBlockPlaceHolder.m
//  NationalRedPacket
//
//  Created by 张子琦 on 2018/6/5.
//  Copyright © 2018 XLook. All rights reserved.
//

#import "XLBlockWrapper.h"

#pragma mark -
#pragma mark Objective-C Block Define

struct XLBlockImpl {
    void *isa;
    int flags;
    int reserved;
    void *func;
    struct XLBlockDesc* desc;
};

struct XLBlockDesc {
    unsigned long int reserved;
    unsigned long int size;
    void (*copy)(void *dst, void *src);     // IFF (1<<25)
    void (*dispose)(void *src);             // IFF (1<<25)
};

enum {
    XLBlockFlagHasCopyDispose = (1 << 25),
    XLBlockFlagHasCtor = (1 << 26),
    XLBlockFlagIsGlobal = (1 << 28),
    XLBlockFlagHasStret = (1 << 29),
    XLBlockFlagHasSignature = (1 << 30)
} XLBlockFlag;

@interface XLBlockWrapper ()
/// Block 的方法签名，retval、blockref、args
@property (strong, nonatomic) NSMethodSignature *signature;
/// 被保存的 Block
@property (strong, nonatomic) id block;
@end

@implementation XLBlockWrapper

#pragma mark -
#pragma mark Public Methods

/**
 包装 Block，方便传递或者是做参数校验

 @param block Block
 */
- (void)wrapBlock:(id)block {
    self.block = block;
}

/**
 获得内部解包的 Block

 @return Block
 */
- (id)unwrapBlock {
    return self.block;
}

#pragma mark -
#pragma mark Getter & Setter

/**
 获取 Block 的签名，description 后的格式为：
    v@?@，v：返回值；@?：blockref；@：argument。具体可以看 Apple 的 type encoding

 @return Block 签名
 */
- (NSMethodSignature *)signature {
    
    if (_signature) {
        return _signature;
    }
    
    struct XLBlockImpl *blockRef = (__bridge struct XLBlockImpl *)self.block;
    
    if (blockRef->flags & XLBlockFlagHasSignature) {
        void *signatureLocation = blockRef->desc;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (blockRef->flags & XLBlockFlagHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        _signature = [NSMethodSignature signatureWithObjCTypes:(*(const char **)signatureLocation)];
    }
    return _signature;
}

#pragma mark -
#pragma mark Override Equality Methods

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToBlockWrapper:object];
}

- (BOOL)isEqualToBlockWrapper:(XLBlockWrapper *)aWrapper {
    if (self == aWrapper) {
        return YES;
    }
    // 只要两个 block 的 signature 相等，我们就认为他们是相等的
    if ([self.signature isEqual:aWrapper.signature]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    hash += [self.signature hash];
    hash += [self.block hash];
    return hash;
}

@end
