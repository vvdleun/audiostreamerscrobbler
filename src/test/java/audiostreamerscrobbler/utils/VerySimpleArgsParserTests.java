package audiostreamerscrobbler.utils;

import java.lang.invoke.MethodHandle;

import org.junit.Test;

import audiostreamerscrobbler.utils.VerySimpleArgsParser;
import gololang.DynamicObject;

import static java.lang.invoke.MethodType.genericMethodType;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

public class VerySimpleArgsParserTests {
	@Test
	public void mustParseArgumentsCorrectly2() throws Throwable {
		String[] args = { "option1", "option2", "--option3" };
		DynamicObject parser = (DynamicObject)VerySimpleArgsParser.createVerySimpleArgsParser(args);
		
		MethodHandle parseNextInvoker = parser.invoker("parseNext", genericMethodType(1));
		assertEquals("option1", parseNextInvoker.invoke(parser));
		assertEquals("option2", parseNextInvoker.invoke(parser));
		assertEquals("--option3", parseNextInvoker.invoke(parser));
		assertNull(parseNextInvoker.invoke(parser));
	}	
}
