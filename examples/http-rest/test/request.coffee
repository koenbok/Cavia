require "coffee-script"

qurl = require 	"url"
http = require	"http"

request =
	get: (url, callback) ->

		options = qurl.parse url
		options.method = "GET"
		
		req = http.request options, (res) ->
			
			res.body = ""
			res.setEncoding "utf8"
			
			res.on "data", (chunk) -> 
				res.body += chunk
			
			res.on "end", -> 
				callback null, res.body, res
			
			res.on "close", (err) -> 
				callback err, "", res
	
		req.on "error", (e) ->
			callback e, "", null
	
		req.end()
	
	put: (url, data, callback) ->
		
		data = JSON.stringify(data)
		
		options = qurl.parse url
		options.method = "PUT"
		options.headers =
			"Content-Type": "application/json"
			"Content-Length": data.length

		req = http.request options, (res) ->
			
			res.body = ""
			res.setEncoding "utf8"
			
			res.on "data", (chunk) -> 
				res.body += chunk
			
			res.on "end", -> 
				callback null, res.body, res
			
			res.on "close", (err) -> 
				callback err, "", res
	
		req.on "error", (e) ->
			callback e, "", null
		
		req.write data
		
		req.end()

exports.request = request
