var tileId;
var tile;
var listenToTicks = true;

$(document).ready(function() {
    tileId = window.location.hash.replace('#', '');

    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });

    socket.on('tick', function(data) {
        if(listenToTicks && data.hasOwnProperty(tileId))
            tick(data[tileId])
    });

    var getTile = function() {
        return $.get('/tiles/' + tileId, function(data) {
            tile = data;
            init();

            listenToTicks = true;
        });
    };

    socket.on('newTile',  function(data) { 
        if(data.tileId == tileId) {
            listenToTicks = false;
            doneTile(); 
            getTile();
        }
    });
    socket.on('doneTile', function(data) { 
        if(data.tileId == tileId) doneTile(); 
    });

    getTile();
})