var currentSessions = [];
var tiles = {};
var rooms  = ['251', '252', '253', 'bleu', '243', '242', '241',
              'havane', '351', '352', '353', '343', '342', '341', 'bordeaux'];

$(document).ready(function() {

    $.getJSON('http://' + window.location.hostname + ':8000/ongoingsessions', function(data) {
        currentSessions = data;

        // TODO: order of sessions != order of rooms
        for(var i = 0; i < currentSessions.length; i++) {
            var room = rooms[i];
            var session = currentSessions[i];
            var timeline = '<div class="session"></div>';

            for(var j = 0; j < session.submissions.length; j++) {
                var sub = session.submissions[j];
                var type = (sub.contributionType == 'Paper') ? 'long' : (sub.contributionType == 'Note') ? 'short' : 'altchi';
                timeline += '<div id="' + sub.id + '" class="submission ' + type + '"></div>';
            }

            $('#' + room + ' .timeline').html(timeline);
        }
    }); 

    // Copied from tile.js but we want it across all tiles   

    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });

    socket.on('tick', tick);

    var getTile = function(tileId) {
        return $.get('/tiles/' + tileId, function(data) {
            tiles[tileId] = data;
            init(tileId);
        });
    };

    socket.on('newTile',  function(data) { getTile(data.tileId); });
    socket.on('doneTile', function(data) { doneTile(data.tileId); });

    // getTile();
});

function init(tileId) {
    var filter = tiles[tileId].filter;
    for(var i = 0; i < filter.submissions.length; i++)
        $('#' + filter.submissions[i].id).append('<div class="tile tile' + tileId + '"></div>');
}

function doneTile(tileId) {
    $('.tile' + tileId).fadeOut(400, function() {
        $('.tile' + tileId).remove();
    });
}

function tick(data) {
    $('.tile.selected').removeClass('selected');
    for(var tileId in data) {
        var idx = data[tileId];
        var sub = tiles[tileId].filter.submissions[idx];
        $('#' + sub.id + ' .tile' + tileId).addClass('selected');
    }
}