const assert = require("node:assert/strict");
const comby = require("../_build/default/bin/comby_lite.bundle.js");

const source = "foo(1); foo(2);";
const matches = JSON.parse(comby.match(source, "foo(:[x])", ".js", ""));

assert.equal(matches.length, 2);
assert.equal(matches[0].environment[0].variable, "x");
assert.equal(matches[0].environment[0].value, "1");
assert.equal(matches[1].environment[0].value, "2");

assert.equal(
  comby.rewrite(source, "foo(:[x])", "bar(:[x])", ".js", ""),
  "bar(1); bar(2);"
);

const regexMatches = JSON.parse(comby.match("abc123 def456", ":[x~[a-z]+]:[n~[0-9]+]", ".txt", ""));
assert.equal(regexMatches.length, 2);
const regexEnv = Object.fromEntries(regexMatches[0].environment.map(({ variable, value }) => [variable, value]));
assert.equal(regexEnv.x, "abc");
assert.equal(regexEnv.n, "123");
assert.equal(comby.getRegexBackend(), "js");

console.log("ok");
