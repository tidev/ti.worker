# Titanium Worker Module

This is a Titanium module that provides a [Web Worker](http://www.whatwg.org/specs/web-apps/current-work) like interface to applications built with Titanium.

This module is designed to be used when applications need to process asynchronous application logic. Due to the limitations of Javascript engines; tasks will not be executed on a seperate thread, but instead executed asynchronously.

## Example

The following is a trivial echo background service.  In your `app.js`, use the following:

```js
var worker = require('ti.worker');

// create a worker thread instance
var task = worker.createWorker('echo.js');

// subscribe to any worker thread instance messages
task.addEventListener('message',function(event){
	
	// data that is sent will be in the data property
	alert(event.data);
	
	// stop terminating this thread instance
	task.terminate();
});

// send data to the worker thread which will be posted on the threads event queue
// you can send any data here
task.postMessage({
	msg:'Hello'
});
```

Now, in a separate file named `echo.js`, use the following:

```js
// subscribe to events send with postMessage
worker.addEventListener('message',function(event){
	
	// send data back to any subscribers
	// pull data from the event from the data property
	worker.postMessage(event.data.msg);
});
```
Note: the `worker` global variable is always defined inside the worker execution context.

## API

- *postMessage* - send a message to or from the worker thread.  Send any data as the first argument.
- *terminate* - terminate the worker thread and stop as soon as possible processing.
- *nextTick* - this method is only available inside the worker instance and provides an ability to process the function passed on the next available thread event loop cycle.

## Events

- *message* - receive an event. The `data` property of the `event` will contain as-is any data specified as the first argument.
- *terminated* - the worker thread was terminated.

## Properties

The `worker` instance has only one property:

- *url* - the url of the worker thread JS file passed in during creation.

## File Location

In order for your source (worker) files to be picked up, place them in the following directory:

**Alloy:** `/app/lib`

**Classic:** `/Resources`

## Warning

This module is experimental and has not been finalized.

## Legal

Titanium is a registered trademark of TiDev Inc. All Titanium trademark and patent rights were transferred
and assigned to TiDev Inc. on 4/7/2022. Please see the LEGAL information about using our trademarks,
privacy policy, terms of usage and other legal information at https://tidev.io/legal.
