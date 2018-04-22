package audiostreamerscrobbler.utils;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

import audiostreamerscrobbler.utils.UrlUtils;

public class UrlUtilsTests {
	@Test
	public void inputUrlWithoutSchemaMustGetHttpAndEndWithSlash() {
		String url = "1.2.3.4";
		String actual = (String)UrlUtils.createFormattedUrl(url);
		assertEquals(actual, "http://1.2.3.4/");
	}

	@Test
	public void inputUrlThatHasHttpSchemaMustStillBeHttpAndEndWithSlash() {
		String url = "http://1.2.3.4";
		String actual = (String)UrlUtils.createFormattedUrl(url);
		assertEquals(actual, "http://1.2.3.4/");
	}

	@Test
	public void inputUrlThatHasHttpsSchemaMustStillBeHttpsAndEndWithSlash() {
		String url = "https://1.2.3.4";
		String actual = (String)UrlUtils.createFormattedUrl(url);
		assertEquals(actual, "https://1.2.3.4/");
	}
	
	@Test
	public void inputUrlThatEndsWithSlashMustStillEndWithSlash() {
		String url = "http://1.2.3.4/";
		String actual = (String)UrlUtils.createFormattedUrl(url);
		assertEquals(actual, "http://1.2.3.4/");
	}
	
	@Test
	public void inputPathThatEndsWithSlashAndPathThatStartsWithSlashMustBeJoinedCorrectlyAndEndWithOne() {
		String url = "http://1.2.3.4/";
		String path = "/5/6";
		String actual = (String)UrlUtils.createFormattedUrl(url, path);
		assertEquals(actual, "http://1.2.3.4/5/6/");
	}

	@Test
	public void inputPatThathDoesNotEndWithSlashAndPathThatStartsWithSlashMustBeJoinedCorrectlyAndEndWithOne() {
		String url = "http://1.2.3.4";
		String path = "/5/6";
		String actual = (String)UrlUtils.createFormattedUrl(url, path);
		assertEquals(actual, "http://1.2.3.4/5/6/");
	}

	@Test
	public void inputPatThatEndsWithSlashAndPathThatDoesNotStartsWithSlashMustBeJoinedCorrectlyAndEndWithOne() {
		String url = "http://1.2.3.4/";
		String path = "5/6";
		String actual = (String)UrlUtils.createFormattedUrl(url, path);
		assertEquals(actual, "http://1.2.3.4/5/6/");
	}
	
	@Test
	public void inputPathThatDoesNotEndWithSlashAndPathThatDoesNotStartWithSlashMustBeJoinedCorrectlyAndEndWithOne() {
		String url = "https://1.2.3.4";
		String path = "5/6";
		String actual = (String)UrlUtils.createFormattedUrl(url, path);
		assertEquals(actual, "https://1.2.3.4/5/6/");
	}
}