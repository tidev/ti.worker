/**
 * Axway Appcelerator Titanium - ti.worker
 * Copyright (c) 2018 by Axway. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.worker;

import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.KrollRuntime;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.titanium.TiApplication;

@Kroll.proxy(creatableInModule=TiWorkerModule.class)
public class TiWorkerProxy extends KrollProxy {

	private static final String TAG = "TiWorkerProxy";

	private final KrollRuntime runtime = KrollRuntime.getInstance();

	public TiWorkerProxy(final String workerFile) {
		super();

		initKrollObject();

		final KrollModule appModule = TiApplication.getInstance().getModuleByName("App");
		if (appModule != null) {
			appModule.setProperty("currentWorker", this);
		}

		runtime.evalString(
	"(function () {" +
			"  let worker = Ti.App.currentWorker;" +
			"  worker.addEventListener('terminated', () => { worker.nextTick = () => {} });" +
			"  worker.nextTick = (t) => {" +
			"    setTimeout(t, 0);" +
			"  };" +
			"  let workerFile = Ti.Filesystem.getFile('" + workerFile + "');" +
			"  eval(workerFile.read().text);" +
			"})();"
		);

		Log.i(TAG, "Worker " + workerFile + " (" + this + ") is running");
	}

	@Kroll.method
	public void terminate() {
		fireSyncEvent("terminated", null);
	}

	@Kroll.method
	public void postMessage(Object message) {
		final KrollDict data = new KrollDict();
		data.put("data", message);
		fireSyncEvent("message", data);
	}

	@Override
	public String getApiName() {
		return "ti.worker.worker";
	}
}
