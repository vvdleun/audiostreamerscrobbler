module bla

import audiostreamerscrobbler.utils.NetworkUtils

function main = |args| {
	getNetworkInterfaces(): each(|i| {
		println(i)
		println(getBroadcastAddresses(i))
		println("\n\n")
		
	})
}