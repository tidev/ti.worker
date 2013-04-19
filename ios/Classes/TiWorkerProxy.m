/**
 * Titanium Worker Pool Module
 * Copyright (c) 2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiWorkerProxy.h"

@implementation TiWorkerSelfProxy

-(id)initWithParent:(TiProxy*)p url:(NSString*)u pageContext:(id<TiEvaluator>)pg
{
    if ((self = [super _initWithPageContext:pg]))
    {
        _parent = p; // no need to retain
        _url = [u retain];
    }
    return self;
}

-(void)dealloc
{
    RELEASE_TO_NIL(_url);
    _parent = nil;
    [super dealloc];
}

-(id)url
{
    return _url;
}

-(void)postMessage:(id)msg
{
    ENSURE_SINGLE_ARG(msg,NSObject); 
    // this is from the worker, posting back to the creator
    NSDictionary *dict = [NSDictionary dictionaryWithObject:msg forKey:@"data"];
    TiWorkerProxy *proxy = (TiWorkerProxy*)_parent;
    [proxy fireMessageEvent:dict];
}

-(void)terminate:(id)args
{
    // if we call terminate on ourselves, just go through the normal route
    [((TiWorkerProxy*)_parent) terminate:args];
}

@end


@implementation TiWorkerProxy

-(id)makeTemp:(NSData*)data
{
	NSString * tempDir = NSTemporaryDirectory();
	NSError * error=nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if(![fm fileExistsAtPath:tempDir])
	{
		[fm createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:&error];
		if(error != nil)
		{
			//TODO: ?
			NSLog(@"TiWorkerProxy makeTemp createDirectoryAtPath error: %@", [error localizedDescription]);
			return nil;
		}
	}
	
	int timestamp = (int)(time(NULL) & 0xFFFFL);
	NSString * resultPath;
	do 
	{
		resultPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%X",timestamp]];
		timestamp ++;
	} while ([fm fileExistsAtPath:resultPath]);
	
    [data writeToFile:resultPath options:NSDataWritingFileProtectionComplete error:&error];
	
	if (error != nil)
	{
		//TODO: ?
		NSLog(@"TiWorkerProxy makeTemp writeToFile error: %@", [error localizedDescription]);
		return nil;
	}
    return resultPath;	
}

-(id)initWithPath:(NSString*)path host:(id)host pageContext:(id<TiEvaluator>)pg
{
    if ((self = [super _initWithPageContext:pg]))
    {
		if (!path)
		{
			NSLog(@"ti.worker module error: path is nil");
		}
		else 
		{
			if ([path isEqualToString:@""])
			{
				NSLog(@"ti.worker module error: path is empty");
			}
			else
			{
				NSLog(@"ti.worker 'path' is '%@'", path);
			}
		}
		
			
		if (!host)
			NSLog(@"ti.worker module error: host is nil");
		
		if (!pg)
			NSLog(@"ti.worker module error: pg is nil");
	
        // the kroll bridge is effectively our JS thread environment
        _bridge = [[KrollBridge alloc] initWithHost:host];
        NSURL *_url = [TiUtils toURL:path proxy:self];
        
        NSLog(@"[INFO] loading worker %@",path);
        
        _lock = [[NSRecursiveLock alloc] init];

        _selfProxy = [[TiWorkerSelfProxy alloc] initWithParent:self url:path pageContext:_bridge];

        NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:_selfProxy,@"currentWorker",nil];
        NSDictionary *preload = [NSDictionary dictionaryWithObjectsAndKeys:values,@"App",nil];

        NSData *data = [TiUtils loadAppResource:_url];
		if (data==nil)
		{
			data = [NSData dataWithContentsOfURL:_url];
		}
        
        NSString *jcode = nil;
        NSError *error = nil;
        if (data==nil)
		{
			jcode = [NSString stringWithContentsOfFile:[_url path] encoding:NSUTF8StringEncoding error:&error];
		}
		else
		{
			jcode = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		}

        // pull it in to some wrapper code so we can provide a start function and pre-define some variables/functions
        NSString *wrapper = [NSString stringWithFormat:@"function TiWorkerStart__(){ var worker = Ti.App.currentWorker; worker.nextTick = function(t) { setTimeout(t,0); }; %@ };", jcode];
        
        // we delete file below when booted
        _tempFile = [[self makeTemp:[wrapper dataUsingEncoding:NSUTF8StringEncoding]] retain];
		NSLog(@"ti.worker tempFile path is %@", _tempFile);
        NSURL *tempurl = [NSURL fileURLWithPath:_tempFile isDirectory:NO];// URLWithString:_tempFile];
		NSLog(@"ti.worker temp url is %@", tempurl.absoluteString);
        
        // start the boot which will run on its own thread automatically
        [_bridge boot:self url:tempurl preload:preload];
    }
    return self;
}

-(void)dealloc
{
    RELEASE_TO_NIL(_selfProxy);
    RELEASE_TO_NIL(_bridge);
    RELEASE_TO_NIL(_lock);
    RELEASE_TO_NIL(_tempFile);
    [super dealloc];
}

-(KrollBridge*)_bridge
{
    return _bridge;
}

-(void)booted:(id)bridge
{
    // this callback is called when the thread is up and running
    [_lock lock];
    _booted = YES;
    NSLog(@"[INFO] worker %@ (0x%X) is running", [_selfProxy url], self);
    [_selfProxy setExecutionContext:_bridge];
    [[NSFileManager defaultManager] removeItemAtPath:_tempFile error:nil];
    RELEASE_TO_NIL(_tempFile);
    [_lock unlock];
    // start our JS processing
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_bridge evalJSWithoutResult:@"TiWorkerStart__();"];
    });
}

-(void)fireMessageEvent:(id)dict
{
    [_lock lock];
    if (_booted)
    {
        // only fire events while we're not terminated
        [self fireEvent:@"message" withObject:dict];
    }
    [_lock unlock];
}

-(void)terminate:(id)args
{
    [_lock lock];
    if (_bridge)
    {
        _booted = NO;
        [_bridge enqueueEvent:@"terminated" forProxy:_selfProxy withObject:args withSource:_selfProxy];
        // we need to give time to process the terminated event
        [self performSelector:@selector(shutdown:) withObject:nil afterDelay:0.5];
        [self fireEvent:@"terminated"];
        RELEASE_TO_NIL(_selfProxy);
        RELEASE_TO_NIL(_bridge);
        NSLog(@"[INFO] terminated worker (0x%X)", self);
    }
    [_lock unlock];
}

-(void)postMessage:(id)args
{
    [_lock lock];
    if (_booted)
    {
        ENSURE_SINGLE_ARG(args,NSObject); 
        NSDictionary *dict = [NSDictionary dictionaryWithObject:args forKey:@"data"];
        [_bridge enqueueEvent:@"message" forProxy:_selfProxy withObject:dict /*withSource:_selfProxy*/];
    }
    else
    {
        // keep trying until we're booted
        [self performSelectorInBackground:@selector(postMessage:) withObject:args];
    }
    [_lock unlock];
}


@end
