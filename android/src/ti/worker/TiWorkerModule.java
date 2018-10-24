/**
 * Axway Appcelerator Titanium - ti.worker
 * Copyright (c) 2018 by Axway. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.worker;

import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.annotations.Kroll;

@Kroll.module(name="tiworker", id="ti.worker")
public class TiWorkerModule extends KrollModule {

	private static final String TAG = "TiWorkerModule";

	public TiWorkerModule() {
		super();
	}

	@Kroll.method
	public TiWorkerProxy createWorker(final String workerFile) {
		return new TiWorkerProxy(workerFile);
	}

	@Override
	public String getApiName() {
		return "ti.worker";
	}
}
