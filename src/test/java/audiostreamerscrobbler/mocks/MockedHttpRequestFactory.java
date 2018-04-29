package audiostreamerscrobbler.mocks;

import java.util.HashMap;
import java.util.Map;

import gololang.FunctionReference;

public class MockedHttpRequestFactory {
	private String encoding;
	private int timeout;
	private Map<String, String> customProperties;
	private UrlGetRequestedCallback urlGetRequestedCallback;
	
	public MockedHttpRequestFactory() {
		this("utf-8", 5);
	}
	
	public MockedHttpRequestFactory(String encoding, int timeout) {
		this(encoding, timeout, new HashMap<>());
	}
	
	public MockedHttpRequestFactory(String encoding, int timeout, Map<String, String> customProperties) {
		this.encoding = encoding;
		this.timeout = timeout;
		this.customProperties = customProperties;
	}
	
	public MockedHttpRequest createHttpRequest() {
		return new MockedHttpRequest(this, encoding, timeout, customProperties);
	}

	public void encoding(String encoding) {
		this.encoding = encoding;
	}

	public int timeout() {
		return timeout;
	}

	public void timeout(int timeout) {
		this.timeout = timeout;
	}

	public Map<String, String> customProperties() {
		return customProperties;
	}

	public void customProperties(Map<String, String> customProperties) {
		this.customProperties = customProperties;
	}

	public void setGetUrlRequestedCallback(UrlGetRequestedCallback urlGetRequestedCallback) {
		this.urlGetRequestedCallback = urlGetRequestedCallback;
	}
	
	@FunctionalInterface
	public interface UrlGetRequestedCallback {
		public Object createGetRequestResult(int index, String url, String accept);
	}
	
	private class MockedHttpRequest {
		private String encoding;
		private int timeout;
		private Map<String, String> customProperties;
		private int getRequestIndex = 0;
		
		public MockedHttpRequest(MockedHttpRequestFactory factory, String encoding, int timeout, Map<String, String> customProperties) {
			this.encoding = encoding;
			this.timeout = timeout;
			this.customProperties = customProperties;
		}
		
		public Object doHttpGetRequestAndReturnJSON(String url) {
			return null;
		}

		public Object doHttpPostRequestAndReturnJSON(String url, String contentType, FunctionReference outputCallback) throws Throwable {
			return null;
		}

		private Object mockPostRequest(String url, String contentType, FunctionReference outputCallback) throws Throwable {
//			reset();
//
//			this.mockedUrls.add(url);
//			
//			ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
//			outputCallback.invoke(byteArrayOutputStream);
//			this.mockedPostedData = byteArrayOutputStream.toByteArray();
//			
//			return outputCallback.invoke(mockedResults.get(index++));
			return null;
		}
		
		public Object doHttpGetRequestAndReturnAsText(String url) {
			return null;
		}
		
		public Object doHttpPostRequestAndReturnAsText(String url, FunctionReference outputCallback, String contentType) throws Throwable {
			return null;
		}
		
		public Object doHttpGetRequest(String url, String accept, FunctionReference inputHandler) throws Throwable {
			return inputHandler.invoke(urlGetRequestedCallback.createGetRequestResult(getRequestIndex++, url, accept));
		}
		
		public String encoding() {
			return encoding;
		}

		public int timeout() {
			return timeout;
		}

		public Map<String, String> customProperties() {
			return customProperties;
		}
	}
}
