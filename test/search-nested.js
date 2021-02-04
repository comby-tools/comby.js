const { match, rewrite } = require("../js/comby.js")

console.log(match("(a(b)c(d))", "(:[1])", ".go", ""));
