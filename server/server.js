var express = require('express');
var bodyParser = require('body-parser');
var app = express();

var url = require('url');
const { match, rewrite } = require("../js/comby.js")

app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: false })); // support encoded bodies

app.post('/rewrite', function (req, res) {
   console.log("Got a POST request for /rewrite");
   console.log('Body:', req.body);
   console.log(req.body.data + " " + req.body.match_template + " " + req.body.rewrite_template);
   var result = rewrite(req.body.data, req.body.match_template, req.body.rewrite_template);
   res.send(result);
})

var server = app.listen(3289, function () {
   var host = server.address().address
   var port = server.address().port
   
   console.log("Example app listening at http://%s:%s", host, port)
})
