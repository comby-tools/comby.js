const { rewrite } = require("./js/comby.min.js");

const { program } = require('commander');
program
  .requiredOption('-m, --match <string>', 'match template')
  .requiredOption('-r, --rewrite <string>', 'rewrite template')
  .requiredOption('-s, --string <string>', 'string to rewrite')
  .option('-R, --rules <string>', 'rewrite rules');
program.parse(process.argv);

const {string, rewrite: rewriteTemplate, match, rules} = program.opts();
console.log(rewrite(string, match, rewriteTemplate, rules ?? "where true"));
