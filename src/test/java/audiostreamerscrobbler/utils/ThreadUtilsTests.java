package audiostreamerscrobbler.utils;

import gololang.FunctionReference;
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;

import org.junit.Test;

import audiostreamerscrobbler.utils.ThreadUtils;

import static java.lang.invoke.MethodType.genericMethodType;
import static org.junit.Assert.assertEquals;

public class ThreadUtilsTests {
	private static String thread2Name;

	@Test
	public void mustRunInDifferentThread() throws Exception {
		 Thread.currentThread().setName("thread1");
		 MethodHandles.Lookup lookup = MethodHandles.lookup();
		 MethodHandle handle = lookup.findStatic(ThreadUtilsTests.class, "functionToRun", genericMethodType(0));
		 FunctionReference functionReference = new FunctionReference(handle);
		 Thread t = (Thread)ThreadUtils.runInNewThread(functionReference);
		 t.join();
		 assertEquals("thread1", Thread.currentThread().getName());
		 assertEquals("thread2", thread2Name);
	}
	
	@SuppressWarnings("unused")
	private static Object functionToRun() {
		Thread.currentThread().setName("thread2");
		thread2Name = Thread.currentThread().getName();
		return null;
	}
}
