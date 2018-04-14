module audiostreamerscrobbler.utils.ThreadUtils

import java.lang.Thread

function runInNewThread = |f| {
	let runnable = asInterfaceInstance(Runnable.class, f)
	let thread = Thread(runnable)
	thread: start()
}