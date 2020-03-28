module audiostreamerscrobbler.maintypes.SongType

struct Song = {
	name,
	artist,
	album,
	position,
	length
}

augment Song {
	function friendlyName = |this| -> "\"" + this: name() + "\" (" + this: artist() + ", \"" + this: album() + "\"), played " + this: position() + " seconds of " + this: length() + " seconds"
}