var url = require('url');
var http = require('http');

const { match, rewrite } = require("../js/comby.js")

//create a server object:
http.createServer(function (req, res) {
  var parsed_url = url.parse(req.url, true);
  var q = parsed_url.query;
  var pathname = parsed_url.pathname
  res.writeHead(200);
  console.log('request ', req.url);
  console.log('pathname ', pathname);
  if (pathname == "/rewrite") {
      console.log(q.data + " " + q.match_template + " " + q.rewrite_template);
      var result = rewrite(q.data, q.match_template, q.rewrite_template);
      res.write(result);
  }
  res.end(); //end the response
}).listen(3289);
