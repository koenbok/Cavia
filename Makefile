REPORTER = list
TIMEOUT = 2000


all: build

build:
	@./node_modules/coffee-script/bin/coffee \
		-c \
		-o lib src

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
		test/*.coffee

testw:
	@./node_modules/mocha/bin/mocha \
		--watch \
		--growl \
		--compilers coffee:coffee-script \
		--reporter $(REPORTER) \
		--timeout $(TIMEOUT) \
		test/*.coffee

.PHONY: build clean watch test