var fs = require("fs");
var julia = require("./julia.node");
var express = require("express");

var app = express();

app.use("/", express.static("static"));

app.get("/julia", function(req, res) {
    var w = req.query.w;
    var h = req.query.h;
    var a = req.query.a;
    var b = req.query.b;
    var scale = req.query.scale;
    var x1 = req.query.x1;
    var y1 = req.query.y1;
    var x2 = req.query.x2;
    var y2 = req.query.y2;

    // Invoking assembly-based julia image generator
    julia.generatePart(w, h, a, b, scale, x1, y1, x2, y2, function(path) {
        fs.readFile(path, function(err, data) {
            fs.unlink(path, function() {});
            res.writeHead(200, {"Content-Type": "image/png"});
            res.end(data, "binary");
        });
    });
});

var server = app.listen(2411, function() {
    var host = server.address().address;
    var port = server.address().port;

    console.log("Listening at http://%s:%s", host, port);
});
