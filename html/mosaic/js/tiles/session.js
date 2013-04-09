var items = [];
var durations = {};

function init() {
    items = [];
    durations = {};
    if(!tile.hasOwnProperty('filter'))
        return;

    var filter = tile.filter;
    console.log("Initializing tile " + filter.tileId);

    if(!filter.hasOwnProperty('query') || !filter.hasOwnProperty('submissions'))
    { console.log('!!! No filter or submissions'); return; }

    $('body').attr('id', 'tile_' + tileId);

    // Submissions will be for multiple rooms, sort rooms in order
    var submissions = filter.submissions;
    submissions.sort(function(a, b) {
        var roomA = parseInt(a.room),
            roomB = parseInt(b.room);

        if(roomA != NaN && roomB != NaN)
            return (roomA - roomB);

        if(a.room == 'Bordeaux' || a.room == 'Havane' || b.room == 'Blue')
            return -1;

        if(a.room == 'Blue' || b.room == 'Bordeaux' || b.room == 'Havane')
            return 1;  
    });

    submissions.forEach(function(s) {
        items.push(s);
        durations[s['room']] || (durations[s['room']] = []);
        durations[s['room']].push({
            id: s['_id'],
            duration: s.duration > 80 ? 80 : s.duration
        });
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
        html += '<h3 class="code">' + item.letterCode + '</h3>';
        // html += '<h4>' + item.affiliation + '</h4>';
        html += '</div></div>';
        $('#submissions').append(html);
    }

    for(var room in durations) {
        var schedule = durations[room];
        for(var i = 0; i < schedule.length; i++) {
            $('<div></div>')
                .addClass('schedule').addClass(room).addClass(schedule[i].id)
                .css('width', schedule[i].duration / 80 * 100 + '%')
                .appendTo('#timeline');
        }
    }

    $('h1').text('Loading...');

    // // Set heights
    // var fullHeight = $('body').height() - 15 - $('h1').height();
    // $('#submissions').height(fullHeight);
}

function tick(ti) {
    itemIndex = ti % items.length;
    if(!tile.hasOwnProperty('filter'))
        return;

    console.log($('body').attr('id') + ' tick ' + ti);

    $('body').attr('class', '').addClass('room_' + items[itemIndex].room.replace('362/363', '362'));
    $('h1').text('Room: ' + items[itemIndex].room);
    $('#timeline .schedule').hide();
    $('#timeline .' + items[itemIndex].room).removeClass('active').show();
    $('#timeline .' + items[itemIndex]['_id']).addClass('active');

    $('.submission.active').each(function(index, self) {
        $('.submission.active .video').html('');

        var $this = $(this);
        $this.removeClass('active').animate({
            left: -($this.width())-100,
        }, 500);
    });

    var $target = $('.submission:eq(' + itemIndex + ')')
    $target.addClass('active').show().css({
        left: $target.width()+100
    }).animate({
        left: 0
    }, 500, 'swing', function() {
        if(items[itemIndex].videoPreviewFile)
            $('.submission.active .video').html('<video height="100%" autoplay="1" muted="1" src="http://92.243.30.77:8000/videos/' + items[itemIndex].videoPreviewFile + '"></video>');
    });

    $('#progress_bar circle').removeClass('active');
    $('#progress_bar circle:eq(' + ti + ')').addClass('active');
}

function doneTile() {
    $('body').attr('id', '');
    $('h1').text('');
    $('#timeline').html('');
    $('#submissions').html('');
    $('#progress_bar').svg('destroy');
    $('#progress_bar').html('');
}
