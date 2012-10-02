var TileId;

$(document).ready(function() {
    TileId = window.location.hash.replace('#', '');

    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });

    socket.on('tick', function(data) {
        tick(data[TileId])
    });

    var getTile = function() {
        return $.get('/tiles/' + TileId, function(data) {
            init(data);
        });
    };

    socket.on('tilesUpdated', function(data) { getTile(); });

    getTile();
})