/**
 * Titanium Worker Pool Module
 * Copyright (c) 2012-present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "KrollBridge.h"
#import "TiProxy.h"

@interface TiWorkerSelfProxy : TiProxy {
  TiProxy *_parent;
  NSString *_url;
}

- (id)initWithParent:(TiProxy *)parent url:(NSString *)u pageContext:(id<TiEvaluator>)pageContext;

@end

@interface TiWorkerProxy : TiProxy {
  KrollBridge *_bridge;
  TiWorkerSelfProxy *_selfProxy;
  BOOL _booted;
  dispatch_queue_t _serialQueue;
  NSString *_tempFile;
}

#pragma mark Private API's

- (id)initWithPath:(NSString *)path host:(id)host pageContext:(id<TiEvaluator>)pageContext;
- (KrollBridge *)_bridge;

#pragma mark Public API's

- (void)terminate:(id)args;
- (void)fireMessageEvent:(id)args;

@end
