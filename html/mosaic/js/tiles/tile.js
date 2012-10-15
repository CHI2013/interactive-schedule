var tileId;
var tile;

$(document).ready(function() {
    tileId = window.location.hash.replace('#', '');

    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });

    socket.on('tick', function(data) {
        if(data.hasOwnProperty(tileId))
            tick(data[tileId])
    });

    var getTile = function() {
        return $.get('/tiles/' + tileId, function(data) {
            tile = data;
            init();
        });
    };

    socket.on('newTile',  function(data) { if(data.tileId == tileId) getTile(); });
    socket.on('doneTile', function(data) { if(data.tileId == tileId) doneTile(); });

    getTile();
})