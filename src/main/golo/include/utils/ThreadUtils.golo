module audiostreamerscrobbler.utils.ThreadUtils

import java.lang.Thread

function runInNewThread = |f| {
	return runInNewThread(null, f)
}

function runInNewThread = |name, f| {
	let runnable = asInterfaceInstance(Runnable.class, f)
	let thread = Thread(runnable)
	if (name isnt null) {
		thread: setName(name)
	}
	thread: start()
	return thread
}