const { match, rewrite } = require("../js/comby.js")

console.log(rewrite("C { uint immutable x = 0; }","{:[1]}","{}",""));
