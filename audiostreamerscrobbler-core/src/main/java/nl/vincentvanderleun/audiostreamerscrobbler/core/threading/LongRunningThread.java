package nl.vincentvanderleun.audiostreamerscrobbler.core.threading;

import nl.vincentvanderleun.audiostreamerscrobbler.core.threading.impl.RunnableAdapter;
import nl.vincentvanderleun.audiostreamerscrobbler.core.threading.impl.ThreadStateManagerImpl;

public class LongRunningThread {
	private final ManagedThread managedThread;

	private LongRunningThreadImpl thread;

	public LongRunningThread(String threadName, Runnable runnable) {
		this(new RunnableAdapter(threadName, runnable));
	}

	public LongRunningThread(ManagedThread managedThread) {
		this.managedThread = managedThread;
	}
	
	public synchronized void start() {
		if(thread != null) {
			thread.stop();
		}
		thread = new LongRunningThreadImpl(managedThread);
		thread.start();
	}
	
	public synchronized void stop() {
		thread.stop();
	}

	public String getName() {
		return thread.getName();
	}
	
	public ThreadState getStatus() {
		return thread.getStatus();
	}
	
	private static class LongRunningThreadImpl implements Runnable {
		private final Thread thread;
		private final ManagedThread managedThread;
		
		private volatile ThreadStateManagerImpl stateManager;

		private LongRunningThreadImpl(ManagedThread managedThread) {
			this.managedThread = managedThread;
			this.thread = new Thread(this);
			this.stateManager = new ThreadStateManagerImpl();
		}

		@Override
		public void run() {
			boolean running = true;

			stateManager.changeToStartingStateNow();
			while(running) {
				try {
					switch(stateManager.getStatus()) {
						case STARTING:
							managedThread.start();
							stateManager.changeToRunningStateWhenNotStopped();
							break;
						case RUNNING:
							// Can stay running, or switch to either STARTING (if not stopped in the meantime)
							// or STOPPING state.
							managedThread.run(stateManager);
							break;
						case STOPPING:
							running = false;
							break;
						default:
							break;
					}
				} catch(Exception ex) {
					managedThread.exception(stateManager.getStatus(), ex);
				}
			}

			try {
				managedThread.stop();
			} catch(Exception ex) {
				managedThread.exception(stateManager.getStatus(), ex);
			} finally {
				stateManager.changeStateToStoppedState();
			}
		}
		
		void start() {
			thread.start();
		}

		void stop() {
			stateManager.stop();
		}
		
		String getName() {
			return thread.getName();
		}
		
		ThreadState getStatus() {
			return stateManager.getStatus();
		}
	}
}
