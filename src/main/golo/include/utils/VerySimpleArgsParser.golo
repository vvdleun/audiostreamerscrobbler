module audiostreamerscrobbler.utils.VerySimpleArgsParser

function createVerySimpleArgsParser = |args| {
	let parser = DynamicObject("VerySimpleArgsParser"):
		define("_args", args):
		define("_index", 0):
		define("parseNext", |this| {
			let index = this: _index()
			let args = this: _args()
			if (index >= args: length()) {
				return null
			}
			let v = args: get(index)
			this: _index(index + 1)
			return v
		})

	return parser
}