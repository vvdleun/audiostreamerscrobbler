package audiostreamerscrobbler.mocks;

import static java.lang.invoke.MethodType.genericMethodType;

import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;

import gololang.FunctionReference;

public class GoloUtils {
	public static FunctionReference createFunctionReference(Class<?> clazz, String methodName, int parameters) throws Throwable {
		MethodHandles.Lookup lookup = MethodHandles.lookup();
		MethodHandle handle = lookup.findStatic(clazz, methodName, genericMethodType(parameters));
		return new FunctionReference(handle);
	}
}
