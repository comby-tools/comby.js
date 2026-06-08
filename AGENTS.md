# Agent Notes

This file records implementation details that are useful for future coding
agents and maintainers. Keep the README user-facing.

## Kernel Source

This package is currently based on `comby-redux/comby/lib/kernel`, not the older
`comby-js` experiment.

The kernel is the simplified Omega-only path. The JS entrypoint is
`bin/comby_js.ml`.

## JavaScript Regex Backend

Regex holes go through `lib/kernel/matchers/regexp.ml`.

`Regexp.Active` selects the backend:

- `JavaScript`: default under js_of_ocaml output.
- `Re`: default for native/bytecode and available as a JS runtime fallback.

The JS bundle exports:

- `setRegexBackend("js" | "re")`
- `getRegexBackend()`

The JavaScript backend intentionally uses a simple first implementation:

- construct a non-global `RegExp`
- anchor the pattern as `^(?:pattern)` to preserve parser-position matching
- copy/slice the current parser input into a JS string
- run `RegExp.exec`

Do not use js_of_ocaml's `Regexp.regexp` helper here without care: it constructs
global regexes, which introduces `lastIndex` state and is a poor fit for parser
combinator matching.

JavaScript `RegExp` syntax differs from PCRE/OCaml `Re`. In particular, POSIX
classes like `[[:alpha:]]` are not JavaScript regex syntax. Prefer JS syntax like
`[A-Za-z]` in JS-facing tests and docs.

## Vangstrom / Trampoline

The build preserves the old `comby-js` js_of_ocaml/Vangstrom trampoline patch by
postprocessing the generated bundle in `bin/dune`:

```text
max_steps = 20 -> max_steps = 1
```

This remains necessary for large inputs in default Node.

The Omega parser also avoids a separate stack issue by using `skip_many` for the
top-level fuzzy scan instead of `many` when the parser result is ignored. The
important shape is:

```ocaml
skip_many first_match_attempt *> end_of_input
```

Using `many first_match_attempt` builds a large recursive result list that is
discarded later and can overflow the JS stack.

## Rewrite Performance

In-place rewrite uses a one-pass buffer implementation. It appends unmatched
source spans and replacement strings into a `Buffer` rather than repeatedly
slicing and concatenating a rolling output string.

This avoids quadratic behavior for many replacements.

## Tests

Useful checks:

```sh
npm run build
node test/smoke.js
node test/regex-suite.js
node test/cli-smoke.js
node bench/large.js 10000
```

The npm scripts run `opam exec -- ...` against the active switch. Override with
`OPAMSWITCH=... npm run build` when using another prepared switch.

The OCaml 5 update was verified in the local `comby-ocaml-5.4.1` switch after
opam resolved its compiler to OCaml 5.3.0 for the js_of_ocaml/Jane Street
package set.

## Node CLI

`bin/comby.js` is the installable Node command. It is intentionally a thin
wrapper around the exported JS bundle so CLI behavior can evolve without
changing the js_of_ocaml entrypoint.

The wrapper first loads `dist/comby.js`, then falls back to
`_build/default/bin/comby_js.bundle.js` for development checkouts. Keep
user-facing command docs in `README.md`; keep implementation details here.

For OCaml 5 Jane Street packages, `bin/dune` links `core/runtime.js`,
`ppx_expect.runtime/runtime.js`, and `ocaml_intrinsics_kernel/runtime.js`. The
older `core_kernel/runtime.js`, `core_kernel/strftime.js`, and
`ppx_expect:collector/runtime.js` paths are not present in this package layout.

`test/regex-suite.js` covers shared regex-hole behavior for the default JS backend
and selected cases for the `Re` fallback. Anchor-sensitive cases are intentionally
handled separately because Comby's parser-level `^`/`$` wrapping is distinct from
plain JavaScript regex matching.
