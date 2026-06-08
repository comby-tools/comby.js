.PHONY: all build test clean

all: build

build:
	npm run build

test:
	npm test

clean:
	opam exec -- dune clean
	rm -rf dist
	rm -f comby-js-*.tgz
