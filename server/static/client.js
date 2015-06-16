var $screen, ctx;
var posx, posy;
var a, b, scale = 0.005, relscale = 1;
var wcnt = 5, hcnt = 4;
var stepx = 20, stepy = 20;
var loaded = {};
var meter;

function clearCache() {
    loaded = {};
}

function isChunkLoaded(x, y) {
    return loaded[x] && loaded[x][y];
}

function loadChunk(x1, y1, x2, y2, cb) {
    if (isChunkLoaded(x1, y1)) {
        cb(x1, y1);
    } else {
        var pieceParams = "a=" + a + "&b=" + b + "&x1=" + x1 + "&y1=" + y1 + "&x2=" + x2 + "&y2=" + y2 + "&scale=" + scale;
        var chunk = new Image();
        chunk.src = "/julia?" + pieceParams;
        chunk.onload = function() {
            if (!loaded[x1]) {
                loaded[x1] = {};
            }
            loaded[x1][y1] = chunk;
            cb(x1, y1);
        }
    }
}

var entered = false;
function setViewport(sx, sy) {
    if (!entered) {
        entered = true;
 
        var w = $screen.width(), h = $screen.height();
        var dw = Math.ceil(w / wcnt);
        var dh = Math.ceil(h / hcnt);
        var ssx = Math.ceil(sx / dw) * dw;
        var ssy = Math.ceil(sy / dh) * dh;

        var chunk_cnt = 0;
        // count all chunks
        for (var y = ssy - dh; y < h + ssy + dh; y += dh) {
            for (var x = ssx - dw; x < w + ssx + dw; x += dw) {
                chunk_cnt++;
            }
        }

        var chunk_loaded = 0;
        // load all needed chunks
        ctx.fillRect(0, 0, w, h);
        for (var y = ssy - dh; y < h + ssy + dh; y += dh) {
            for (var x = ssx - dw; x < w + ssx + dw; x += dw) {
                loadChunk(x, y, x + dw, y + dh, function(x, y) {
                    ctx.drawImage(loaded[x][y], x - sx, y - sy);
                    // release lock
                    if (++chunk_loaded == chunk_cnt) {
                        entered = false;
                    }
                });
            }
        }

        meter.tick();
    }
}

// one way of treading Julia set is by keyboard
$(document).keydown(function(e) {
    var w = $screen.width(), h = $screen.height();

    if (e.target != document.body) {
        return;
    }

    switch (e.which) {
        case 37: // left
            posx -= stepx;
            setViewport(posx, posy);
            e.preventDefault();
            break;

        case 38: // up
            posy -= stepy;
            setViewport(posx, posy);
            e.preventDefault();
            break;

        case 39: // right
            posx += stepx;
            setViewport(posx, posy);
            e.preventDefault();
            break;

        case 40: // down
            posy += stepy;
            setViewport(posx, posy);
            e.preventDefault();
            break;

        case 187: // +-ish
            if (!entered) {
                scale /= 2;
                relscale *= 2;
                $("#scale").html(relscale);
                clearCache();
                setViewport(posx, posy);
            }
            e.preventDefault();
            break;

        case 189: // -
            if (!entered) {
                scale *= 2;
                relscale /= 2;
                $("#scale").html(relscale);
                clearCache();
                setViewport(posx, posy);
            }
            e.preventDefault();
            break;
    }
});

$(document).ready(function() {
    var w = $(document).width();
    var h = $(document).height();

    $screen = $("<canvas/>");
    $screen.css({
        position: "absolute",
        left: "0",
        top: "0"
    });
    $screen.attr({
        width: $(document).width(),
        height: $(document).height()
    });
    $screen.appendTo("body");
    ctx = $screen[0].getContext("2d");

    meter = new FPSMeter(document.body, {
        "left": "auto",
        "top": "5px",
        "right": "5px",
        "theme": "transparent"
    });

    a = $("#a").val();
    b = $("#b").val();

    posx = Math.floor(-w / 2);
    posy = Math.floor(-h / 2);
    setViewport(posx, posy);

    // another is by mouse
    var dragging = false;
    var prevx = -1, prevy;

    $($screen).mousedown(function() {
        dragging = true;
    });

    $($screen).mouseup(function() {
        dragging = false;
        prevx = -1;
    });

    $($screen).mouseout(function() {
        dragging = false;
        prevx = -1;
    });

    $($screen).mousemove(function(e) {
        if (dragging) {
            var curx = e.clientX;
            var cury = e.clientY;

            if (prevx != -1) {
                posx += ~~((prevx - curx) * 1.5);
                posy += ~~((prevy - cury) * 1.5);
                setViewport(posx, posy);
            }

            prevx = curx;
            prevy = cury;
        }
    });

    $("#a").keyup(function(e) {
        if (e.keyCode == 13) {
            a = $("#a").val();
            b = $("#b").val();
            clearCache();
            setViewport(posx, posy);
        }
    });

    $("#b").keyup(function(e) {
        if (e.keyCode == 13) {
            a = $("#a").val();
            b = $("#b").val();
            clearCache();
            setViewport(posx, posy);
        }
    });

    $("#a").addClass("prevent");
    $("#b").addClass("prevent");
});
