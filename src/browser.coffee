exports ?= {}

stubs =
	util:
		inspect: ->


window.sqlbt = exports
window.require = (name) ->
	console.log "[require] #{name}"
	lib = window.sqlbt[name]
	lib ?= stubs[name]