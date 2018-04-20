/**
 * Titanium Worker Pool Module
 * Copyright (c) 2012-present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiWorkerModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiWorkerProxy.h"

@implementation TiWorkerModule

#pragma mark Internal

- (id)moduleGUID
{
  return @"d97e8b6c-a598-4b21-be51-26449733a49d";
}

- (NSString *)moduleId
{
  return @"ti.worker";
}

- (TiWorkerProxy *)createWorker:(id)args
{
  ENSURE_SINGLE_ARG(args, NSString);
  return [[TiWorkerProxy alloc] initWithPath:args host:[self _host] pageContext:[self executionContext]];
}

@end
