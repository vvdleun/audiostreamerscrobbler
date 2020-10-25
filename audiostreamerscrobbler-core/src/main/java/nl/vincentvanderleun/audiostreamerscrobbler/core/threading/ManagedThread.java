package nl.vincentvanderleun.audiostreamerscrobbler.core.threading;

public interface ManagedThread {
	default public void start() throws Exception {
	}

	public void run(ThreadStateManager stateManager);
	
	default public void stop() throws Exception {
	}
	
	default public void exception(ThreadState state, Exception ex)  {
		System.out.println("[" + getName() + "] Exception while in state " + state + ": " + ex.getMessage());
	}
	
	public String getName();
}
