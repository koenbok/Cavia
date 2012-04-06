Key value implementation on top of sql with forced indexes. A bit like AppEngines BigTable.

## Api docs

```
new Backend <"dsl">, <[models]>

store.create <"kind">, callback
store.get <"kind">, <"key", [keys]>, callback
store.put <"kind">, <{data}, [{data}]>, callback
store.del <"kind">, <"key", [keys]>, callback
store.query <"kind">, <{filters}>, callback
```

## Run the tests

make test

