var items = [];
var durations = {};

function init() {
    if(!tile.hasOwnProperty('filter'))
        return;

    var filter = tile.filter;
    console.log("Initializing tile " + filter.tileId);

    if(!filter.hasOwnProperty('query') || !filter.hasOwnProperty('sessions'))
    { console.log('!!! No filter or sessions'); return; }

    $('body').attr('id', 'tile_' + tileId);

    // Submissions will be for multiple rooms, sort rooms in order
    var sessions = filter.sessions;
    sessions.sort(function(a, b) {
        var roomA = parseInt(a.room),
            roomB = parseInt(b.room);

        if(roomA != NaN && roomB != NaN)
            return (roomA - roomB);

        if(a.room == 'Bordeaux' || a.room == 'Havane' || b.room == 'Blue')
            return -1;

        if(a.room == 'Blue' || b.room == 'Bordeaux' || b.room == 'Havane')
            return 1;  
    });

    sessions.forEach(function(s) {
        if(s.submissions.length == 0) {
            items.push(s);
            durations[s['_id']] = [80];
        } else {
            s.submissions.forEach(function(ss) {
                items.push(ss);
                durations[ss['session']] || (durations[ss['session']] = []);
                durations[ss['session']] = ss.duration;
            });
        }
    });

    for(var i = 0; i < items.length; i++) {
        var item = items[i];
        var authorList = item.authorList || [];
        for(var j = 0; j < authorList.length; j++)
            authorList[j] = authorList[j].familyName + ', ' + authorList[j].givenName.charAt(0).toUpperCase() + '.';

        var html = '<div class="submission">';
        html += '<div class="video" align="center"></div>';
        html += '<div class="info">';
        html += '<h2>' + item.title + '</h2>';
        html += '<h3>' + authorList.join(', ') + '</h3>';
        html += '<h3 class="code">abc</h3>';
        // html += '<h4>' + item.affiliation + '</h4>';
        html += '</div></div>';
        $('#submissions').append(html);
    }

    $('h1').text('Loading...');

    // Set heights
    var fullHeight = $('body').height() - 15 - $('h1').height();
    $('#submissions').height(fullHeight);
}

function tick(ti) {
    if(!tile.hasOwnProperty('filter'))
        return;

    console.log($('body').attr('id') + ' tick ' + ti);

    $('h1').text('Room: ' + items[ti].room);

    $('.submission.active').each(function(index, self) {
        $('.submission.active .video').html('');

        var $this = $(this);
        $this.removeClass('active').animate({
            left: -($this.width())-100,
        }, 500);
    });

    var $target = $('.submission:eq(' + ti + ')')
    $target.addClass('active').show().css({
        left: $target.width()+100
    }).animate({
        left: 0
    }, 500, 'swing', function() {
        if(items[ti].videoPreviewFile)
            $('.submission.active .video').html('<video height="100%" autoplay="1" src="http://92.243.30.77:8000/videos/' + items[ti].videoPreviewFile + '"></video>');
    });

    $('#progress_bar circle').removeClass('active');
    $('#progress_bar circle:eq(' + ti + ')').addClass('active');
}

function doneTile() {
    $('body').attr('id', '');
    $('h1').text('');
    $('#submissions').html('');
    $('#progress_bar').svg('destroy');
    $('#progress_bar').html('');
}
