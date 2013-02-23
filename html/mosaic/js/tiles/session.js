var submissions = [];

function init() {
    if(!tile.hasOwnProperty('filter'))
        return;

    var filter = tile.filter;
    console.log("Initializing tile " + filter.tileId);

    if(!filter.hasOwnProperty('query') || !filter.hasOwnProperty('submissions'))
    { console.log('!!! No filter or submissions'); return; }

    $('body').attr('id', 'tile_' + tileId);

    // Submissions will be for multiple rooms, sort rooms in order
    submissions = filter.submissions;
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

    for(var i = 0; i < submissions.length; i++) {
        var item = submissions[i];
        var authorList = item.authorList;
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

    $('h1').text('Room: ' + submissions[ti].room);

    $('.submission.active').each(function(index, self) {
        $('.submission.active .video').html('');

        var $this = $(this);
        $this.removeClass('active').animate({
            left: -($this.width())-100,
        }, 500).hide();
    });

    var $target = $('.submission:eq(' + ti + ')')
    $target.addClass('active').show().css({
        left: $target.width()+100
    }).animate({
        left: 0
    }, 500, 'swing', function() {
        $('.submission.active .video').html('<video height="100%" autoplay="1" src="http://92.243.30.77:8000/videos/' + submissions[ti].videoPreviewFile + '"></video>');
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
