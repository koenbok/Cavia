async = require "async"
{request} = require "./request"

uuid = ->

	chars = '0123456789abcdefghijklmnopqrstuvwxyz'.split('')
	output = new Array(36)
	random = 0

	for digit in [1..32]
		random = 0x2000000 + (Math.random() * 0x1000000) | 0 if (random <= 0x02)
		r = random & 0xf
		random = random >> 4
		output[digit] = chars[if digit == 19 then (r & 0x3) | 0x8 else r]

	output.join('')


data =
	name: "Mat Tozer"
	age: 29
	
async.map [0..300], (i, cb) ->
	
	auuid = uuid()
	
	request.put "http://localhost:5000/api/persons/#{auuid}", JSON.stringify(data), (err, data, res) ->
		throw err if err
		console.log data

, ->
	console.log "DONE"

# request.put "http://localhost:8000/persons/#{uuid()}", JSON.stringify(data), (err, data, res) ->
# 	throw err if err
# 	console.log data