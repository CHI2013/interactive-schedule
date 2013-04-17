var items = [];
var durations = {};
var roomOrder = ['251', '252A', '252B', '253', '241', '242A', '242B', '242AB', '243', 'Blue', 'Havane', '351', '352AB', 'Bordeaux', '342A', '343', '361', '362/363', 'interactivity'];

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
    var submissions = {};

    filter.submissions.forEach(function(s) {
        var loc = s.room || s.venue;
        submissions[loc] || (submissions[loc] = []);
        submissions[loc].push(s);

        durations[loc] || (durations[loc] = []);
        durations[loc].push({
            id: s['_id'],
            duration: s.duration > 80 ? 80 : s.duration
        });
    });

    roomOrder.forEach(function(r) { 
        if(submissions[r])
            items = items.concat(submissions[r]); 
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
}

function tick(ti) {
    itemIndex = ti % items.length;
    if(!tile.hasOwnProperty('filter'))
        return;

    console.log($('body').attr('id') + ' tick ' + ti);

    var item = items[itemIndex],
        room = getRoom(item.room || item.venue);

    $('body').attr('class', '').addClass(getClass(item)).addClass(tile.when + '_tile').addClass('volatile_' + tile.volatile);

    $('#timeline').html('');
    if(item.hasOwnProperty('sessionDurations')) {
        item.sessionDurations.forEach(function(d) {
            $('<div></div>')
                .addClass('schedule').addClass(room).addClass(d.submission)
                .css('width', d.duration / 80 * 100 + '%')
                .appendTo('#timeline');
        });
    }
    $('#timeline .' + item['_id']).addClass('active');

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
        if(item.letterCode)
            $('.submission.active .video').html('<video height="100%" autoplay="1" muted="1" src="http://chischedule.org/2013/' + item.letterCode + '"></video>');
    });

    $('#volatile_label').html(titleCaps(tile.filter.query.authorKeywords.join(' & ')) + '<br />' + (ti+1) + '/' + items.length);
    $('#volatile_room').text(room);
}

function doneTile() {
    $('body').attr('id', '').attr('class', '');
    $('#timeline').html('');
    $('#submissions').html('');
}

function getClass(item) {
    if(item.room)
        return 'room_' + getRoom(item.room);
    else if(item.venue)
        return 'venue_' + item.venue;
}

function getRoom(r) {
    return r.replace('362/363', '362');
}
