# comby-lite

This is a small extraction of the current `comby` kernel for JavaScript builds.

It intentionally builds the Omega matcher path and excludes the older Alpha matcher
because Alpha depends on `MParser_PCRE`/PCRE C stubs. The Omega regex-hole path is
patched to use the pure OCaml `Re` backend so the bytecode can be transpiled with
`js_of_ocaml`.

Build:

```sh
opam install . --deps-only
opam exec -- dune build bin/comby_lite.bundle.js
node test/smoke.js
node bench/large.js 10000
```

Exports:

- `match(source, matchTemplate, languageOrExtension, rule)`: returns JSON matches.
- `rewrite(source, matchTemplate, rewriteTemplate, languageOrExtension, rule)`: returns the rewritten source.
- `rewriteJson(...)`: returns a JSON object with `rewritten_source`.
- `substitute(template, environmentJson)`: substitutes a rewrite template with a match environment.

Notes:

- This is extracted from current `comby/lib/kernel`, not from the older flattened
  `comby.js/lib` copy.
- The old `comby.js` trampoline postprocess is preserved in `bin/dune` by lowering
  Vangstrom's generated `max_steps` from `20` to `1`.
- Omega's top-level fuzzy scan uses `skip_many` instead of `many` for the ignored
  parser result, which avoids the default Node stack overflow seen around 1800
  repeated matches.
- Regex holes currently use the pure OCaml `Re` backend. The backend boundary is
  `lib/kernel/matchers/regexp.ml`'s `Regexp_engine_intf`, which is the place to
  experiment with JavaScript `RegExp` later.
- See `NOTES.md` for the current-code vs old-`comby.js` comparison and benchmark
  notes.
