all: best

# With rule options in src/dune. Disable inlining to get a good size but always working JS.
best:
	@dune build @@default
	@cp _build/install/default/bin/comby.js js
	@sed -i .orig "s|steps=\[0,20|steps=\[0,1|" js/comby.js
	@sed -i .orig "s|max_steps=20|max_steps=1|" js/comby.js
	@rm js/comby.js.orig
	@du -h js/comby.js
	@uglifyjs js/comby.js -o js/comby.min.js
	@du -h js/comby.min.js

# Using dune for separate compiliation. Produces a bigger final JS file, but always works.
build:
	@dune build ./src/comby.bc.js --profile dev
	@cp ./_build/default/src/comby.bc.js js/comby.debug.js
	@du -h js/comby.debug.js
	@sed -i .orig "s|steps=\[0,20|steps=\[0,1|" js/comby.debug.js
	@sed -i .orig "s|max_steps=20|max_steps=1|" js/comby.debug.js
	@rm js/comby.debug.js.orig

# Uses dune direct complation. Enables inlining, which undos tramplining and the examples don't work.
release:
	@dune build ./src/comby.bc.js --profile release
	@cp ./_build/default/src/comby.bc.js js/comby.opt.js
	@du -h js/comby.opt.js
	@sed -i .orig "s|steps=\[0,20|steps=\[0,1|" js/comby.opt.js
	@sed -i .orig "s|max_steps=20|max_steps=1|" js/comby.opt.js
	@rm js/comby.opt.js.orig

test:
	@cd test && ./test.sh

clean:
	@dune clean

promote:
	@dune promote

.PHONY: all build release test clean promote test
