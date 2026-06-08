const comby = require("../_build/default/bin/comby_lite.bundle.js");

const n = Number(process.argv[2] || 10000);
const source = Array.from({ length: n }, (_, i) => `foo(${i});`).join("\n");

const t0 = performance.now();
const matches = JSON.parse(comby.match(source, "foo(:[x])", ".js", ""));
const t1 = performance.now();
const rewritten = comby.rewrite(source, "foo(:[x])", "bar(:[x])", ".js", "");
const t2 = performance.now();

console.log(JSON.stringify({
  lines: n,
  matches: matches.length,
  rewrittenBytes: rewritten.length,
  matchMs: Math.round(t1 - t0),
  rewriteMs: Math.round(t2 - t1),
}));
