/**
 * Titanium Worker Pool Module
 * Copyright (c) 2012-present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiWorkerProxy.h"

@implementation TiWorkerSelfProxy

- (id)initWithParent:(TiProxy *)p url:(NSString *)u pageContext:(id<TiEvaluator>)pg
{
  if ((self = [super _initWithPageContext:pg])) {
    _parent = p; // no need to retain
    _url = u;
  }
  return self;
}

- (NSString *)url
{
  return _url;
}

- (void)postMessage:(id)msg
{
  ENSURE_SINGLE_ARG(msg, NSObject);
  // this is from the worker, posting back to the creator
  NSDictionary *dict = [NSDictionary dictionaryWithObject:msg forKey:@"data"];
  TiWorkerProxy *proxy = (TiWorkerProxy *)_parent;
  [proxy fireMessageEvent:dict];
}

- (void)terminate:(id)args
{
  // if we call terminate on ourselves, just go through the normal route
  [((TiWorkerProxy *)_parent) terminate:args];
}

@end

@implementation TiWorkerProxy

- (id)makeTemp:(NSData *)data
{
  NSString *tempDir = NSTemporaryDirectory();
  NSError *error = nil;

  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:tempDir]) {
    [fm createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
      //TODO: ?
      return nil;
    }
  }

  int timestamp = (int)(time(NULL) & 0xFFFFL);
  NSString *resultPath;
  do {
    resultPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%X", timestamp]];
    timestamp++;
  } while ([fm fileExistsAtPath:resultPath]);

  [data writeToFile:resultPath options:NSDataWritingFileProtectionComplete error:&error];

  if (error != nil) {
    //TODO: ?
    return nil;
  }
  return resultPath;
}

- (id)initWithPath:(NSString *)path host:(id)host pageContext:(id<TiEvaluator>)pg
{
  if ((self = [super _initWithPageContext:pg])) {
    if (!path || [path isEqualToString:@""]) {
      NSLog(@"[ERROR] Ti.Worker error: path error");
    }

    if (!host) {
      NSLog(@"[ERROR] Ti.Worker error: host error");
    }

    if (!pg) {
      NSLog(@"[ERROR] Ti.Worker error: context error");
    }

    // the kroll bridge is effectively our JS thread environment
    _bridge = [[KrollBridge alloc] initWithHost:host];
    NSURL *_url = [TiUtils toURL:path proxy:self];

    NSLog(@"[INFO] Loading worker %@", path);

    _serialQueue = dispatch_queue_create("ti.worker", DISPATCH_QUEUE_SERIAL);

    _selfProxy = [[TiWorkerSelfProxy alloc] initWithParent:self url:path pageContext:_bridge];

    NSData *data = [TiUtils loadAppResource:_url];
    if (data == nil) {
      data = [NSData dataWithContentsOfURL:_url];
    }

    NSString *jcode = nil;
    NSError *error = nil;
    if (data == nil) {
      jcode = [NSString stringWithContentsOfFile:[_url path] encoding:NSUTF8StringEncoding error:&error];
    } else {
      jcode = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    // pull it in to some wrapper code so we can provide a start function and pre-define some variables/functions
    // the newline after the wrapped code is important due to trailing sourcemap comment
    NSString *wrapper = [NSString stringWithFormat:@"function TiWorkerStart__() { var worker = Ti.App.currentWorker; worker.nextTick = function(t) { setTimeout(t,0); }; %@\n};", jcode];

    // we delete file below when booted
    _tempFile = [[self makeTemp:[wrapper dataUsingEncoding:NSUTF8StringEncoding]] retain];
    NSURL *tempurl = [NSURL fileURLWithPath:_tempFile isDirectory:NO];
    // start the boot which will run on its own thread automatically
    [_bridge boot:self url:tempurl preload:@{ @"App" : @{ @"currentWorker" : _selfProxy } }];
  }
  return self;
}

- (KrollBridge *)_bridge
{
  return _bridge;
}

- (void)booted:(id)bridge
{
  // this callback is called when the thread is up and running
  dispatch_async(_serialQueue, ^{
    _booted = YES;
    NSLog(@"[INFO] Worker %@ (0x%X) is running", [_selfProxy url], self);
    [_selfProxy setExecutionContext:_bridge];
    [[NSFileManager defaultManager] removeItemAtPath:_tempFile error:nil];
    [_tempFile release];
  });

  // start our JS processing
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [_bridge evalJSWithoutResult:@"TiWorkerStart__();"];
  });
}

- (void)fireMessageEvent:(id)dict
{
  dispatch_async(_serialQueue, ^{
    if (_booted) {
      // only fire events while we're not terminated
      [self fireEvent:@"message" withObject:dict];
    }
  });
}

- (void)terminate:(id)args
{
  dispatch_async(_serialQueue, ^{
    if (_bridge) {
      _booted = NO;
      [_bridge enqueueEvent:@"terminated" forProxy:_selfProxy withObject:args];

      // we need to give time to process the terminated event
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self contextShutdown:nil];
      });

      [self fireEvent:@"terminated"];
      NSLog(@"[INFO] Terminated worker (0x%X)", self);
    }
  });
}

- (void)postMessage:(id)args
{
  ENSURE_SINGLE_ARG(args, NSObject);

  dispatch_async(_serialQueue, ^{
    if (_booted) {
      [_bridge enqueueEvent:@"message" forProxy:_selfProxy withObject:@{ @"data" : args }];
    } else {
      dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
      dispatch_async(queue, ^{
        [self postMessage:args];
      });
    }
  });
}

@end
