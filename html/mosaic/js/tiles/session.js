function init() {
    if(!tile.hasOwnProperty('filter'))
        return;

    var filter = tile.filter;
    console.log("Initializing tile " + filter.tileId);

    if(!filter.hasOwnProperty('query') || !filter.hasOwnProperty('submissions'))
    { console.log('!!! No filter or submissions'); return; }
    
    $('body').attr('id', 'tile' + filter.tileId);
    $('h1').text(titleCaps(filter.query.tags.join(' & ')))

    // The first slide is just a list of titles
    var first = '<div id="first" class="active submission"><div class="inner">';
    for(var i = 0; i < filter.submissions.length; i++)
        first += '<h2>' + filter.submissions[i].title + '</h2>';
    first += '</div></div>';
    $('#submissions').append(first);

    for(var i = 0; i < filter.submissions.length; i++) {
        var item = filter.submissions[i];
        var html = '<div class="submission"><div class="inner">';
        html += '<h2>' + item.title + '</h2>';
        html += '<h3>' + item.authors.join(', ') + '</h3>';
        // html += '<h4>' + item.affiliation + '</h4>';
        html += '</div></div>';
        $('#submissions').append(html);
    }

    $('#progress_bar').svg({ onLoad: function(svg) {
        var cxCenter = ($('body').width()-40*filter.submissions.length)/2;

        for(var i = 0, cx = cxCenter; i < filter.submissions.length; i++, cx+=50)
            svg.circle(cx, 10, 10);
    }});
}

function tick(ti) {
    if(!tile.hasOwnProperty('filter'))
        return;

    console.log($('body').attr('id') + ' tick ' + ti);

    $('.submission.active').each(function(index, self) {
        var $this = $(this);
        $this.removeClass('active').animate({
            left: -($this.width())-100,
        }, 500);
    });

    var $target = $('.submission:eq(' + (ti+1) + ')')
    $target.addClass('active').show().css({
        left: $target.width()+100
    }).animate({
        left: 0
    }, 500);

    $('#progress_bar circle').removeClass('active');
    $('#progress_bar circle:eq(' + ti + ')').addClass('active');

    window.setTimeout(function() { showVideo(ti); }, 5000);
}

function showVideo(ti) {
    $('#submissions').fadeOut(250, function() {
        $('#video').fadeIn(250, function() {
            jwplayer('player').setup({
                flashplayer: '/lib/jwplayer/player.swf',
                file: '/videos/' + tile.filter.submissions[ti].video,
                width: $('#video').width(),
                height: $('#video').height(),
                mute: true,
                controlbar: "none",
                duration: 15,
                autostart: true,
                events: {
                    onComplete: function() {
                        $('#video').fadeOut(250, function() {
                            $('#submissions').fadeIn(250);
                        })
                    }
                }
            });
        })
    });
}

function doneTile() {
    $('body').attr('id', '');
    $('h1').text('');
    $('#submissions').html('');
    $('#progress_bar').svg('destroy');
    $('#progress_bar').html('');
}
