const { match, rewrite } = require("../js/comby.js")

console.log(rewrite("{x} {y} {z}","{:[1]}","{}",'where :[1] == "y"'));
