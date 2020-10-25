module nl.vincentvanderleun.audiostreamerscrobbler.core {
	requires static lombok;

	requires java.net.http;

	exports nl.vincentvanderleun.audiostreamerscrobbler.core.model;
	exports nl.vincentvanderleun.audiostreamerscrobbler.core.net;
}