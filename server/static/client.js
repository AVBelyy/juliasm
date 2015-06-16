var screen, ctx;
var posx, posy, scale = 0.001;
var wcnt = 8, hcnt = 6;
var stepx = 20, stepy = 20;
var loaded = {};
var juliaParams = "w=1000&h=500&a=-0.8&b=0.136";

function clearCache() {
    loaded = {};
}

function isChunkLoaded(x, y) {
    return loaded[x] && loaded[x][y];
}

function loadChunk(x1, y1, x2, y2, cb) {
    if (isChunkLoaded(x1, y1)) {
        cb();
    } else {
        var pieceParams = "x1=" + x1 + "&y1=" + y1 + "&x2=" + x2 + "&y2=" + y2 + "&scale=" + scale;
        var chunk = new Image();
        chunk.src = "/julia?" + juliaParams + "&" + pieceParams;
        chunk.onload = function() {
            if (!loaded[x1]) {
                loaded[x1] = {};
            }
            loaded[x1][y1] = chunk;
            cb();
        }
    }
}

var entered = false;
function setViewport(sx, sy) {
    if (!entered) {
        entered = true;
 
        var w = screen.width(), h = screen.height();
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
        for (var y = ssy - dh; y < h + ssy + dh; y += dh) {
            for (var x = ssx - dw; x < w + ssx + dw; x += dw) {
                loadChunk(x, y, x + dw, y + dh, function() {
                    // display visible chunks 
                    ctx.fillRect(0, 0, w, h);
                    for (var yy = ssy - dh; yy < h + ssy + dh; yy += dh) {
                        for (var xx = ssx - dw; xx < w + ssx + dw; xx += dw) {
                            if (isChunkLoaded(xx, yy)) {
                                ctx.drawImage(loaded[xx][yy], xx - sx, yy - sy);
                            }
                        }
                    }
                    // release lock
                    if (++chunk_loaded == chunk_cnt) {
                        entered = false;
                    }
                });
            }
        }
    }
}

// one way of treading Julia set is by keyboard
$(document).keydown(function(e) {
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
            scale /= 2;
            clearCache();
            setViewport(posx, posy);
            e.preventDefault();
            break;

        case 189: // -
            scale *= 2;
            clearCache();
            setViewport(posx, posy);
            e.preventDefault();
            break;
    }
});

$(document).ready(function() {
    screen = $("<canvas/>");
    screen.css({
        position: "absolute",
        left: "0",
        top: "0"
    });
    screen.attr({
        width: $(document).width(),
        height: $(document).height()
    });
    screen.appendTo("body");
    ctx = screen[0].getContext("2d");

    posx = posy = 0;
    setViewport(posx, posy);

    var dragging = false;
    var prevx = -1, prevy;

    // another is by mouse
    $(screen).mousedown(function() {
        dragging = true;
    });

    $(screen).mouseup(function() {
        dragging = false;
        prevx = -1;
    });

    $(screen).mouseout(function() {
        dragging = false;
        prevx = -1;
    });

    $(screen).mousemove(function(e) {
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
});