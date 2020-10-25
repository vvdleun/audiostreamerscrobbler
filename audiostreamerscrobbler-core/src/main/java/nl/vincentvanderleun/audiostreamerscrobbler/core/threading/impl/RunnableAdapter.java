package nl.vincentvanderleun.audiostreamerscrobbler.core.threading.impl;

import nl.vincentvanderleun.audiostreamerscrobbler.core.threading.ManagedThread;
import nl.vincentvanderleun.audiostreamerscrobbler.core.threading.ThreadStateManager;

public class RunnableAdapter implements ManagedThread {
	private final String name;
	private final Runnable runnable;
	
	public RunnableAdapter(String name, Runnable runnable) {
		this.name = name;
		this.runnable = runnable;
	}
	
	@Override
	public void run(ThreadStateManager stateManager) {
		runnable.run();
	}

	@Override
	public String getName() {
		return name;
	}
}
