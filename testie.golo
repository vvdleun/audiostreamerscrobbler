module testie.Testie

import java.lang.{Long, String}

function main = |args| {
	var i = Long(0_L)
	while (true) {
		i = i + 1
		let data = JSON.parse("{\"i\": " + i + "}")	
		println(data)
	}	
}