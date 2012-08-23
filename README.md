[![build status](https://secure.travis-ci.org/koenbok/Cavia.png)](http://travis-ci.org/koenbok/Cavia)
[VERY MUCH A WORK IN PROGRESS]

Simple key value implementation on top of old fashioned sql.

## Philosophy

Some stuff I like for storing my data

- A very simple engine with a minimal api (get, put, del, query) so it can be replaced with something more optimized if needed
- Old fashion storage engines that you can hire as a service and install locally
- options (sqlite, mysql, postgresql)
- Data model flexibility, no schemas
- Enforce querying on indexes, so they are always fast
- Separating indexes from the actual data, and dynamically generating them on put
- The ability to cheat on all of the above if you need it
- Transactions and aggregates

Obvious downsides

- No type checking, validation etc.
- Not very space efficient (index is data copy)
- Definitely not the fastest way to store data
 

## Simple Example

```coffee
models = 
	person: 
		kind: "person"
		indexes:
			age: {type: "int", getter: (data) -> data.age}

data =
	key: utils.uuid()
	kind: "person"
	name: "Koen Bok"
	age: 29

backend = new PostgresBackend "postgres://localhost/test"
store = new Store backend, [models.person]

store.create (err) ->
	
	# Store a person (upsert)
	store.put data, (err) ->
		
		# Get a person by key
		store.get "person", data.key (err, result) ->
			console.log result

		# Query persons older then 10 years
		store.query "person", {"name >": "10"}, (err, result) ->
			console.log result
```


## Api

```coffee
new Backend <"dsl">, <[models]>

store.create <"kind">, callback
store.get <"kind">, <"key", [keys]>, callback
store.put <"kind">, <{data}, [{data}]>, callback
store.del <"kind">, <"key", [keys]>, callback
store.query <"kind">, <{filters}>, callback
```

## Run the tests

make test

## Extras

REST API example using express. Deployable to Heroku.

## Todo

- Make it work in the browser with websql database
- Add middleware system and implementations (caching, serializing, performance, logging, structured data validation, authentication)
- Add events action.pre|post
- Refactor transactions to be objects
- Refactor query pattern to something nicer (allowing querying on multiple indexes)
	
## Inspiration

http://backchannel.org/blog/friendfeed-schemaless-mysql