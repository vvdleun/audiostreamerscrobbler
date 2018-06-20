module audiostreamerscrobbler.groups.Group

function createGroup = |name, groupStrategy| {
	let players = list[]

	let group = DynamicObject("Group"):
		define("_groupStrategy", groupStrategy):
		define("name", name):
		define("event", |this, event| -> this: _groupStrategy(): event(this, event))
		
	return group
}
