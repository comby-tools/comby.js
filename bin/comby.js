#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");

function usage() {
  return `Usage:
  comby MATCH_TEMPLATE REWRITE_TEMPLATE [EXTENSION] [FILES...] [OPTIONS]

Examples:
  comby 'foo(:[x])' 'bar(:[x])' .js -stdin -stdout
  comby 'foo(:[x])' '' .js -stdin -match-only -json-lines
  comby 'foo(:[x])' 'bar(:[x])' .js src/file.js -in-place

Options:
  -stdin                 Read source from stdin.
  -stdout                Write rewritten source to stdout.
  -match-only, -o        Print matches instead of rewriting.
  -json-lines            Print one JSON object per input.
  -count                 Print the number of matches.
  -in-place              Rewrite file inputs in place.
  -matcher, -lang, -l    Set language or extension, for example .js.
  -rule RULE             Apply a Comby rule.
  -regex-backend js|re   Select JavaScript RegExp or OCaml Re regex holes.
  -help, --help          Show this help.
  -version, --version    Show package version.`;
}

function loadComby() {
  const root = path.resolve(__dirname, "..");
  const candidates = [
    path.join(root, "dist", "comby.js"),
    path.join(root, "_build", "default", "bin", "comby_js.bundle.js"),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return require(candidate);
    }
  }

  throw new Error(
    "could not find comby-js bundle; run `npm run build` first"
  );
}

function parseArgs(argv) {
  const opts = {
    stdin: false,
    stdout: false,
    matchOnly: false,
    jsonLines: false,
    count: false,
    inPlace: false,
    newlineSeparated: false,
    language: "",
    rule: "",
    regexBackend: "",
    help: false,
    version: false,
    positional: [],
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--") {
      opts.positional.push(...argv.slice(i + 1));
      break;
    }

    switch (arg) {
      case "-help":
      case "--help":
      case "-h":
        opts.help = true;
        break;
      case "-version":
      case "--version":
        opts.version = true;
        break;
      case "-stdin":
        opts.stdin = true;
        break;
      case "-stdout":
        opts.stdout = true;
        break;
      case "-match-only":
      case "-only-matching":
      case "-o":
        opts.matchOnly = true;
        break;
      case "-json-lines":
        opts.jsonLines = true;
        break;
      case "-count":
        opts.count = true;
        break;
      case "-in-place":
      case "-i":
        opts.inPlace = true;
        break;
      case "-newline-separated":
        opts.newlineSeparated = true;
        break;
      case "-matcher":
      case "-m":
      case "-lang":
      case "-language":
      case "-l":
      case "-extensions":
      case "-extension":
        i += 1;
        if (i >= argv.length) {
          throw new Error(`${arg} requires a value`);
        }
        opts.language = firstExtension(argv[i]);
        break;
      case "-rule":
        i += 1;
        if (i >= argv.length) {
          throw new Error("-rule requires a value");
        }
        opts.rule = argv[i];
        break;
      case "-regex-backend":
        i += 1;
        if (i >= argv.length) {
          throw new Error("-regex-backend requires js or re");
        }
        opts.regexBackend = argv[i];
        break;
      default:
        if (arg.startsWith("-")) {
          throw new Error(`unknown option: ${arg}`);
        }
        opts.positional.push(arg);
    }
  }

  return opts;
}

function firstExtension(value) {
  return String(value).split(",").map((part) => part.trim()).filter(Boolean)[0] || "";
}

function splitInputs(opts) {
  const positional = opts.positional.slice();
  const matchTemplate = positional.shift();
  const rewriteTemplate = positional.shift();

  let language = opts.language;
  if (!language && positional.length > 0 && looksLikeLanguage(positional[0])) {
    language = positional.shift();
  }

  return {
    matchTemplate,
    rewriteTemplate: rewriteTemplate || "",
    language: language || ".generic",
    files: positional,
  };
}

function looksLikeLanguage(value) {
  if (value.startsWith(".")) {
    return true;
  }
  if (value.includes("/") || value.includes("\\")) {
    return false;
  }
  return !fs.existsSync(value);
}

function parseMatchJson(json) {
  const parsed = JSON.parse(json);
  if (!Array.isArray(parsed) && parsed && parsed.error) {
    throw new Error(parsed.error);
  }
  return parsed;
}

function emitMatchOutput({ uri, matches, opts }) {
  if (opts.count) {
    return `${uri ? `${uri}:` : ""}${matches.length}\n`;
  }
  if (opts.jsonLines) {
    return `${JSON.stringify({ uri, matches })}\n`;
  }
  return `${JSON.stringify(matches, null, 2)}\n`;
}

function emitRewriteOutput({ uri, rewritten, opts }) {
  if (opts.jsonLines) {
    return `${JSON.stringify({ uri, rewritten_source: rewritten })}\n`;
  }
  if (opts.newlineSeparated && !rewritten.endsWith("\n")) {
    return `${rewritten}\n`;
  }
  return rewritten;
}

function runOnSource({ comby, source, uri, matchTemplate, rewriteTemplate, language, opts }) {
  if (opts.matchOnly || opts.count) {
    const matches = parseMatchJson(
      comby.match(source, matchTemplate, language, opts.rule)
    );
    return emitMatchOutput({ uri, matches, opts });
  }

  const rewritten = comby.rewrite(
    source,
    matchTemplate,
    rewriteTemplate,
    language,
    opts.rule
  );
  return emitRewriteOutput({ uri, rewritten, opts });
}

function main(argv) {
  const opts = parseArgs(argv);
  const packageJson = require(path.join(__dirname, "..", "package.json"));

  if (opts.help) {
    process.stdout.write(`${usage()}\n`);
    return 0;
  }
  if (opts.version) {
    process.stdout.write(`${packageJson.version}\n`);
    return 0;
  }

  const { matchTemplate, rewriteTemplate, language, files } = splitInputs(opts);
  if (!matchTemplate) {
    throw new Error(`missing MATCH_TEMPLATE\n\n${usage()}`);
  }
  if (opts.inPlace && opts.stdin) {
    throw new Error("-in-place cannot be used with -stdin");
  }
  if (opts.matchOnly && opts.inPlace) {
    throw new Error("-in-place cannot be used with -match-only");
  }

  const comby = loadComby();
  if (opts.regexBackend) {
    const selected = comby.setRegexBackend(opts.regexBackend);
    if (String(selected).startsWith("unknown regex backend:")) {
      throw new Error(selected);
    }
  }

  const shouldReadStdin = opts.stdin || (files.length === 0 && !process.stdin.isTTY);
  if (shouldReadStdin) {
    const source = fs.readFileSync(0, "utf8");
    process.stdout.write(
      runOnSource({
        comby,
        source,
        uri: null,
        matchTemplate,
        rewriteTemplate,
        language,
        opts,
      })
    );
    return 0;
  }

  if (files.length === 0) {
    throw new Error(`no input files; pass -stdin or file paths\n\n${usage()}`);
  }

  for (const file of files) {
    const source = fs.readFileSync(file, "utf8");
    const output = runOnSource({
      comby,
      source,
      uri: file,
      matchTemplate,
      rewriteTemplate,
      language,
      opts,
    });
    if (opts.inPlace) {
      fs.writeFileSync(file, output, "utf8");
    } else {
      process.stdout.write(output);
    }
  }

  return 0;
}

if (require.main === module) {
  try {
    process.exitCode = main(process.argv.slice(2));
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = { main, parseArgs, splitInputs };
