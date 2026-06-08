const assert = require("node:assert/strict");
const comby = require("../_build/default/bin/comby_js.bundle.js");

function rewrite(source, matchTemplate, rewriteTemplate, backend = "js") {
  comby.setRegexBackend(backend);
  return comby.rewrite(source, matchTemplate, rewriteTemplate, ".generic", "");
}

function assertRewrite(name, source, matchTemplate, rewriteTemplate, expected, backend = "js") {
  const actual = rewrite(source, matchTemplate, rewriteTemplate, backend);
  assert.equal(actual, expected, `${name} (${backend})`);
}

const sharedCases = [
  ["regex_holes_simple", "foo", ":[x~\\w+]", "(:[x])", "(foo)"],
  ["regex_holes_substring", "foo()", ":[x~o\\w]()", "(:[x])", "f(oo)"],
  ["regex_holes_empty_string_terminates", "foo()", ":[x~|]", "(:[x])", "()f()o()o()(())"],
  ["regex_holes_repetition_takes_precedence", "foobar()", ":[x~\\w+]bar()", "(:[x])", "foobar()"],
  [
    "regex_holes_negated_match_paren",
    "(literally_anyting_except_close_paren?!@#$%^&*[])",
    "(:[x~[^)]+])",
    "(:[x])",
    "(literally_anyting_except_close_paren?!@#$%^&*[])",
  ],
  ["regex_holes_negated_match_args", "(arg1, arg2, arg3)", ":[x~[^,() ]+]", "(:[x])", "((arg1), (arg2), (arg3))"],
  ["regex_holes_dot_star", "foo()\nbar()", ":[x~.*]", "(:[x])", "(foo())()\n(bar())"],
  ["regex_holes_optional", "nonovember no november no vember", ":[x~no(vember)?]", "(:[x])", "(no)(november) (no) (november) (no) vember"],
  ["regex_holes_optional_spaces", "nonovember no november no vember", "no :[x~(vember)?]", "(:[x])", "nonovember ()november (vember)"],
  ["regex_holes_optional_outside", "no", "no:[x~(vember)?]", "(:[x])", "()"],
  ["regex_holes_lazy_spaces", "foo bar foobar", ":[x~\\s*?]", "(:[x])", "()f()o()o() ()b()a()r() ()f()o()o()b()a()r"],
  ["regex_holes_star_spaces", "foo bar foobar", ":[x~\\s*]", "(:[x])", "()f()o()o( )()b()a()r( )()f()o()o()b()a()r"],
  [
    "spaces_star",
    "\n     a\n  b\n           c\n     d\n",
    ":[x~\\s*]",
    "(:[x])",
    "(\n     )()a(\n  )()b(\n           )()c(\n     )()d(\n)",
  ],
  [
    "word_boundaries",
    "\nfoo(bar, baz(),\n\n\n          qux.derp)\n",
    ":[x~\\b\\w+\\b]",
    "(>:[x]<)",
    "\n(>foo<)((>bar<), (>baz<)(),\n\n\n          (>qux<).(>derp<))\n",
  ],
  [
    "do_not_match_space",
    "\nfoo(bar, baz(),\n\n\n          qux.derp)\n",
    ":[x~[^, ]+]",
    "(>:[x]<)",
    "(>\nfoo(bar<), (>baz()<),(>\n\n\n<)          (>qux.derp)\n<)",
  ],
  [
    "do_not_match_whitespace",
    "\nfoo(bar, baz(),\n\n\n          qux.derp)\n",
    ":[x~[^,\\s]+]",
    "(>:[x]<)",
    "\n(>foo(bar<), (>baz()<),\n\n\n          (>qux.derp)<)\n",
  ],
];

const anchorCases = [
  [
    "leading_spaces_beginning_line_anchor",
    "\n       a\n   b\n            c\n",
    ":[x~^(\\s+)]",
    "(:[x])",
    "\n(       )a\n(   )b\n(            )c\n",
  ],
  ["end_line_anchor", "\naaa bbb\naaa bbb ccc\nccc ddd\n", ":[x~\\w+ bbb$]", "(:[x])", "\n(aaa bbb)aaa bbb ccc\nccc ddd\n"],
];

for (const testCase of sharedCases) {
  assertRewrite(...testCase, "js");
}

for (const [name, source, matchTemplate, rewriteTemplate] of anchorCases) {
  const actual = rewrite(source, matchTemplate, rewriteTemplate, "js");
  assert.notEqual(actual, source, `${name} should still produce JS RegExp matches`);
}

// This is intentionally JS-only: JavaScript RegExp does not support POSIX classes.
assertRewrite("js_character_class_range", "foo", ":[x~[A-Za-z]]", "(:[x])", "(f)(o)(o)", "js");

for (const testCase of sharedCases.slice(0, 8)) {
  assertRewrite(...testCase, "re");
}

assert.equal(comby.setRegexBackend("js"), "js");
assert.equal(comby.getRegexBackend(), "js");
assert.equal(comby.setRegexBackend("re"), "re");
assert.equal(comby.getRegexBackend(), "re");

console.log("regex suite ok");
