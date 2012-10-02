var tileId;
var tile;

$(document).ready(function() {
    tileId = window.location.hash.replace('#', '');

    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });

    socket.on('tick', function(data) {
        tick(data[tileId])
    });

    var getTile = function() {
        return $.get('/tiles/' + tileId, function(data) {
            tile = data;
            init();
        });
    };

    socket.on('tilesUpdated', function(data) { getTile(); });

    getTile();
})