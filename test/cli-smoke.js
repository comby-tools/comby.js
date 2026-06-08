const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const cli = path.join(__dirname, "..", "bin", "comby.js");

function run(args, input) {
  const result = spawnSync(process.execPath, [cli, ...args], {
    cwd: path.join(__dirname, ".."),
    input,
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr || result.stdout);
  return result.stdout;
}

assert.equal(
  run(["foo(:[x])", "bar(:[x])", ".js", "-stdin", "-stdout"], "foo(1); foo(2);"),
  "bar(1); bar(2);"
);

const jsonLines = run(
  ["foo(:[x])", "", ".js", "-stdin", "-match-only", "-json-lines"],
  "foo(1); foo(2);"
);
const line = JSON.parse(jsonLines);
assert.equal(line.uri, null);
assert.equal(line.matches.length, 2);

assert.equal(
  run(["foo(:[x])", "", ".js", "-stdin", "-count"], "foo(1); foo(2);"),
  "2\n"
);

assert.equal(
  run([":[word~[a-z]+]", "", ".txt", "-stdin", "-match-only", "-count"], "abc DEF"),
  "1\n"
);

assert.equal(
  run([":[word~[[:alpha:]]+]", "", ".txt", "-stdin", "-match-only", "-count", "-regex-backend", "re"], "abc DEF"),
  "2\n"
);

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "comby-cli-"));
const file = path.join(tmp, "sample.js");
fs.writeFileSync(file, "foo(3);", "utf8");
run(["foo(:[x])", "bar(:[x])", ".js", file, "-in-place"]);
assert.equal(fs.readFileSync(file, "utf8"), "bar(3);");

console.log("ok");
