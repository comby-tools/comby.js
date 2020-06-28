var express = require('express');
var bodyParser = require('body-parser');
var app = express();

var url = require('url');
const { match, rewrite } = require("../js/comby.js")

app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: false })); // support encoded bodies

app.post('/rewrite', function (req, res) {
// console.log("Got a POST request for /rewrite");
// console.log('Body:', req.body);
// console.log(req.body.source + " " + req.body.match + " " + req.body.rewrite);
   var result = rewrite(req.body.source, req.body.match, req.body.rewrite);
   res.send(result);
})

app.post('/mutate', function (req, res) {
// console.log("Got a POST request for /mutate");
// console.log('Body:', req.body);
// console.log(req.body.source + " " + req.body.match + " " + req.body.rewrite);
   var result = rewrite(req.body.source, req.body.match, req.body.rewrite);
// console.log('RESULT: ', result)
   res.send(result);
})



var server = app.listen(4448, function () {
   var host = server.address().address
   var port = server.address().port
   
   console.log("Example app listening at http://%s:%s", host, port)
})
