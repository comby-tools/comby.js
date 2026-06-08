# comby-js

`comby-js` is a JavaScript build of Comby's core structural match and rewrite
engine. It is intended for embedding Comby-style matching in Node or browser
tooling without shelling out to the native `comby` binary.

This package uses the simplified Omega-only kernel from `comby-redux`. Regex
holes default to JavaScript `RegExp` in the generated JS bundle, with OCaml `Re`
available as a fallback.

## Install

Install OCaml dependencies in an OCaml 5 switch:

```sh
opam switch create comby-ocaml-5 ocaml-base-compiler.5.3.0
opam install --switch=comby-ocaml-5 . --deps-only
```

Build the JavaScript bundle and copy it to `dist/`:

```sh
make
```

This runs Dune under the active opam switch and writes:

```text
dist/comby.js
```

To build with a specific switch:

```sh
OPAMSWITCH=my-switch make
```

Clean generated Dune and JavaScript package artifacts:

```sh
make clean
```

Install the local command, if you want `comby` on your `PATH`:

```sh
npm install -g .
```

You can also run it directly from the checkout:

```sh
printf 'foo(1); foo(2);' \
  | node bin/comby.js 'foo(:[x])' 'bar(:[x])' .js -stdin -stdout
```

Run the smoke tests:

```sh
make test
```

Run a synthetic benchmark:

```sh
node bench/large.js 10000
```

## Use

### CLI

`comby` accepts a small Comby-compatible command shape:

```sh
comby MATCH_TEMPLATE REWRITE_TEMPLATE [EXTENSION] [FILES...] [OPTIONS]
```

Run directly from the checkout:

```sh
printf 'foo(1); foo(2);' \
  | node bin/comby.js 'foo(:[x])' 'bar(:[x])' .js -stdin -stdout
```

After `npm install -g .`, invoke the installed binary:

```sh
printf 'foo(1); foo(2);' \
  | comby 'foo(:[x])' 'bar(:[x])' .js -stdin -stdout
```

Print matches as JSON lines:

```sh
printf 'foo(1); foo(2);' \
  | comby 'foo(:[x])' '' .js -stdin -match-only -json-lines
```

Rewrite a file in place:

```sh
comby 'foo(:[x])' 'bar(:[x])' .js src/file.js -in-place
```

Useful options:

- `-stdin`: read source from stdin
- `-stdout`: print rewritten source to stdout
- `-match-only`, `-only-matching`, `-o`: print matches instead of rewriting
- `-json-lines`: print one JSON object per input
- `-count`: print match counts
- `-in-place`: rewrite file inputs in place
- `-matcher`, `-lang`, `-l`: set the matcher extension, for example `.js`
- `-rule RULE`: apply a Comby rule
- `-regex-backend js|re`: select JavaScript `RegExp` or OCaml `Re` regex holes

The CLI currently implements the basic match/rewrite path. It does not include
the full native Comby command surface for project-wide search, interactive
review, diff display, or editor integrations.

### JavaScript API

```js
const comby = require("comby-js");

const source = "foo(1); foo(2);";

const matches = JSON.parse(
  comby.match(source, "foo(:[x])", ".js", "")
);

console.log(matches.length); // 2

const rewritten = comby.rewrite(
  source,
  "foo(:[x])",
  "bar(:[x])",
  ".js",
  ""
);

console.log(rewritten); // "bar(1); bar(2);"
```

The third argument is a language extension or matcher selector, for example
`.js`, `.go`, `.py`, or `.generic`. The fourth argument is an optional Comby rule
string. Pass `""` when no rule is needed.

## API

### `match(source, matchTemplate, languageOrExtension, rule)`

Returns a JSON string containing matches.

```js
const json = comby.match("foo(1)", "foo(:[x])", ".js", "");
const matches = JSON.parse(json);
```

Each match includes:

- `range`: start/end offsets and line/column positions
- `environment`: captured metavariables
- `matched`: the matched source text

### `rewrite(source, matchTemplate, rewriteTemplate, languageOrExtension, rule)`

Returns the rewritten source string.

```js
comby.rewrite("foo(1)", "foo(:[x])", "bar(:[x])", ".js", "");
// "bar(1)"
```

If there are no matches, the original source is returned.

### `rewriteJson(source, matchTemplate, rewriteTemplate, languageOrExtension, rule)`

Returns a JSON string with a `rewritten_source` field.

```js
JSON.parse(comby.rewriteJson("foo(1)", "foo(:[x])", "bar(:[x])", ".js", ""));
// { rewritten_source: "bar(1)" }
```

### `substitute(template, environmentJson)`

Substitutes a rewrite template using a JSON-encoded Comby environment.

This is useful when you already have a match environment from `match()`.

```js
const [first] = JSON.parse(comby.match("foo(1)", "foo(:[x])", ".js", ""));
comby.substitute("bar(:[x])", JSON.stringify(first.environment));
// "bar(1)"
```

### `setRegexBackend("js" | "re")`

Selects the regex backend for regex holes.

```js
comby.setRegexBackend("js"); // default in the JS bundle
comby.setRegexBackend("re"); // OCaml Re fallback
```

Returns the active backend name.

### `getRegexBackend()`

Returns the active regex backend:

```js
comby.getRegexBackend(); // "js" or "re"
```

## Regex Holes

Regex holes use Comby's `:[name~regex]` syntax:

```js
const matches = JSON.parse(
  comby.match("abc123 def456", ":[x~[a-z]+]:[n~[0-9]+]", ".txt", "")
);
```

With the default JS backend this uses JavaScript `RegExp` syntax. Use
JavaScript-style regex patterns such as `[A-Za-z]`.

## Notes

- The generated bundle is CommonJS.
- Implementation details for future maintainers and coding agents are in
  `AGENTS.md`.
