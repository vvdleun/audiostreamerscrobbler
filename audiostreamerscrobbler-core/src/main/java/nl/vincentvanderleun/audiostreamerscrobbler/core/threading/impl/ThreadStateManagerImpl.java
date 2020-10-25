package nl.vincentvanderleun.audiostreamerscrobbler.core.threading.impl;

import nl.vincentvanderleun.audiostreamerscrobbler.core.threading.ThreadState;
import nl.vincentvanderleun.audiostreamerscrobbler.core.threading.ThreadStateManager;

public class ThreadStateManagerImpl implements ThreadStateManager {
	private volatile ThreadState status;

	private final Object lock;
	
	public ThreadStateManagerImpl() {
		status = ThreadState.IDLE;
		lock = new Object();
	}

	// Methods for internal use only
	
	public void changeToStartingStateNow() {
		status = ThreadState.STARTING;
	}

	public void changeToRunningStateWhenNotStopped() {
		synchronized(lock) {
			if(isNotStopped()) {
				status = ThreadState.RUNNING;
			}
		}
	}

	public void changeStateToStoppedState() {
		synchronized(lock) {
			status = ThreadState.STOPPED;
		}
	}

	private boolean isNotStopped() {
		return status != ThreadState.STOPPING
				&& status != ThreadState.STOPPED;
	}

	// Methods that can be called generally

	@Override
	public void stop() {
		synchronized(lock) {
			status = ThreadState.STOPPING;
		}
	}
	
	public ThreadState getStatus() {
		return status;
	}

	// Method to be called by running thread only

	@Override
	public void restart() {
		synchronized(lock) {
			if(status == ThreadState.RUNNING) {
				status = ThreadState.STARTING;
			}
		}
	}
}
