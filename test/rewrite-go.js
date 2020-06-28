const { match, rewrite } = require("../js/comby.js")

var fs = require('fs'),
    path = require('path'),
    filePath = path.join(__dirname, 'search.go');

fs.readFile(filePath, {encoding: 'utf-8'}, function(err,data){
    if (!err) {
        console.log(rewrite(data,"(:[1])","(AYAYA)", ""));
    } else {
        console.log(err);
    }
});
