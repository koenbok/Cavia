REPORTER = list
TIMEOUT = 1000


all: build

build:
	@./node_modules/coffee-script/bin/coffee \
		-c \
		-o lib src
	@cat lib/backend.js >> lib/browser.js
	@cat lib/store.js >> lib/browser.js

clean:
	rm -rf lib
	mkdir lib

watch:
	@./node_modules/coffee-script/bin/coffee \
		-o lib \
		-cw src

test:
	@./node_modules/mocha/bin/mocha \
		--compilers coffee:coffee-script \
		--reporter $(REPORTER) \
		--timeout $(TIMEOUT) \
		--bail \
		test/*.coffee

testw:
	@./node_modules/mocha/bin/mocha \
		--watch \
		--growl \
		--bail \
		--compilers coffee:coffee-script \
		--reporter $(REPORTER) \
		--timeout $(TIMEOUT) \
		test/*.coffee

.PHONY: build clean watch test