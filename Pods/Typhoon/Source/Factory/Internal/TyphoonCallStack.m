////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2013, Typhoon Framework Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////


#import "TyphoonCallStack.h"
#import "TyphoonStackElement.h"
#import "TyphoonRuntimeArguments.h"

@implementation TyphoonCallStack
{
    NSMutableArray *_storage;
    NSMutableArray *_emptyNotificationBlocks;
}


//-------------------------------------------------------------------------------------------
#pragma mark - Class Methods

+ (instancetype)stack
{
    return [[self alloc] init];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Initialization & Destruction

- (id)init
{
    self = [super init];
    if (self) {
        _storage = [NSMutableArray array];
        _emptyNotificationBlocks = [NSMutableArray new];
    }
    return self;
}


//-------------------------------------------------------------------------------------------
#pragma mark - Interface Methods

- (void)push:(TyphoonStackElement *)stackElement
{
#if DEBUG
    if (![stackElement isKindOfClass:[TyphoonStackElement class]]) {
        [NSException raise:NSInvalidArgumentException format:@"Not a TyphoonStackItem: %@", stackElement];
    }
#endif
    [_storage addObject:stackElement];
}

- (TyphoonStackElement *)pop
{
    id element = [_storage lastObject];
    if (![self isEmpty]) {
        [_storage removeLastObject];
    }

    if ([self isEmpty]) {
        [self callNotificationBlocksAndClear];
    }

    return element;
}

- (TyphoonStackElement *)peekForKey:(NSString *)key args:(TyphoonRuntimeArguments *)args
{
    NSUInteger argsHash = [args hash];
    
    NSInteger depth = 0;
    for (TyphoonStackElement *item in [_storage reverseObjectEnumerator]) {
        if ([item.key isEqualToString:key] && argsHash == [item.args hash]) {
            // Circular reference to prototype objects is supported, but only for one level of depth
            // i.e. backward reference is suported, but reference through several levels would be considered
            // as reference to another prototyped instance
            if (!item.isPrototypeElement || depth <= 1) {
                return item;
            }
            
        }
        depth += 1;
    }
    return nil;
}

- (BOOL)isEmpty
{
    return ([_storage count] == 0);
}

- (BOOL)isResolvingKey:(NSString *)key withArgs:(TyphoonRuntimeArguments *)args
{
    return [self peekForKey:key args:args] != nil;
}

- (void)notifyOnceWhenStackEmptyUsingBlock:(void(^)(void))onEmpty
{
    [_emptyNotificationBlocks addObject:onEmpty];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Private

- (void)callNotificationBlocksAndClear
{
    for (void(^notifyBlock)(void) in _emptyNotificationBlocks) {
        notifyBlock();
    }
    [_emptyNotificationBlocks removeAllObjects];
}

@end
