const { match, rewrite } = require("../js/comby.js")

var fs = require('fs'),
    path = require('path'),    
    filePath = path.join(__dirname, 'search10.go');

fs.readFile(filePath, {encoding: 'utf-8'}, function(err,data){
    if (!err) {
		console.log(match(data, "(:[1])", ""));
    } else {
        console.log(err);
    }
});
