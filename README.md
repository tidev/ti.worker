Titanium Worker Thread Module
=============================

This is a Titanium module that provides a [Web Worker](http://www.whatwg.org/specs/web-apps/current-work) like interface to applications built with Titanium.

This module is designed to be used when applications need to process multi-threaded application logic in the background from the main application thread.  These
threads are typically expensive, long-lived tasks which can be executed independent of the application processing or the main UI thread.

It is important to note that even though you can use this library to create worker threads, any processing or rendering that must be done by the UI will always continue
to be single-threaded by the host OS and executed on the main "UI thread", regardless of how many parallel threads are used in the background.

Example
-------

The following is a trivial echo background service.  In your `app.js`, use the following:

<code>var worker = require('ti.worker');
var task = worker.createWorker('echo.js');
task.addEventListener('message',function(event){
	alert(event.data);
	task.terminate();
});
task.postMessage({
	msg:'Hello'
});</code>

Now, in a separate file named `echo.js`, use the following:

<code>worker.addEventListener('message',function(event){
	worker.postMessage(event.data.msg);
});</code>

Note: the `worker` global variable is always defined inside the worker thread execution context.

API
---

*postMessage* - send a message to or from the worker thread.  Send any data as the first argument.
*terminate* - terminate the worker thread and stop as soon as possible processing.
*nextTick* - this method is only available inside the worker instance and provides an ability to process the function passed on the next available thread event loop cycle.

Events
------

*message* - receive an event. The `data` property of the `event` will contain as-is any data specified as the first argument.
*terminated* - the worker thread was terminated.

Properties
----------

The `worker` instance has only one property:

*url* - the url of the worker thread JS file passed in during creation.


Warning
-------

[Concurrent programming](http://en.wikipedia.org/wiki/Concurrent_computing) is dangerous and error prone.  We've designed this library to make it easier to build 
multi-threaded applications in Titanium.  However, you should use at your own risk and make sure you do plenty of testing on different devices. You should also understand
the concepts of concurrent programming before using this module.


Change Log
----------

*1.0* - June 4, 2012

> This is the initial commit and it works only on iOS currently.
	


License
-------
Copyright (c) 2012 by Appcelerator, Inc. All Rights Reserved.
This code is licensed under the terms of the Apache Public License, version 2.

