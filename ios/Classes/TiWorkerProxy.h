/**
 * Titanium Worker Pool Module
 * Copyright (c) 2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiProxy.h"
#import "KrollBridge.h"

@interface TiWorkerSelfProxy : TiProxy {    
    TiProxy *_parent;
    NSString *_url;
}

-(id)initWithParent:(TiProxy*)parent url:(NSString*)u pageContext:(id<TiEvaluator>)pageContext;

@end


@interface TiWorkerProxy : TiProxy {
    KrollBridge *_bridge;
    TiWorkerSelfProxy *_selfProxy;
    BOOL _booted;
    NSRecursiveLock *_lock;
    NSString *_tempFile;
}

-(id)initWithPath:(NSString*)path host:(id)host pageContext:(id<TiEvaluator>)pageContext;
-(KrollBridge*)_bridge;
-(void)terminate:(id)args;
-(void)fireMessageEvent:(id)args;

@end

