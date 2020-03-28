module audiostreamerscrobbler.groups.Group

function createGroup = |name, groupStrategy| {
	let players = list[]

	let group = DynamicObject("Group"):
		define("_groupStrategy", |this| -> groupStrategy):
		define("name", name):
		define("event", |this, e| -> this: _groupStrategy(): event(this, e))
		
	return group
}
