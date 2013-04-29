var items = [];
var durations = {};

function init() {
    items = [];
    durations = {};

    $('#action').hide();
    $('#loading').show();
    $('#submissions').show();
    $('#tagcloud').hide();

    if(!tile.hasOwnProperty('filter'))
        return;

    var filter = tile.filter;
    console.log("Initializing tile " + filter.tileId);

    if(!filter.hasOwnProperty('query') || !filter.hasOwnProperty('submissions'))
    { console.log('!!! No filter or submissions'); return; }

    $('body').attr('id', 'tile_' + tileId);

    filter.submissions.forEach(function(s) {
        var loc = s.room || s.venue;
        items.push(s);

        durations[loc] || (durations[loc] = []);
        durations[loc].push({
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
        html += '<div class="cbStatement" align="center"><p>' + (item.cbStatement || '') + '</p></div>';
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
    if(!tile.hasOwnProperty('filter') || ti == -1)
        return interactiveTile();

    console.log($('body').attr('id') + ' tick ' + ti);

    var item = items[itemIndex],
        room = getRoom(item.room || item.venue);

    $('#loading').hide();
    $('#action').hide();    

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
    if(item.startTime) 
        $('#timeline .' + item['_id']).html('<p>' + item.startTime[3] + ':' + (item.startTime[4] == 0 ? '00' : item.startTime[4]) + '</p>');
        

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
        if(item.hasVideo && item.letterCode) {
            $('.submission.active .video').html('<video height="100%" autoplay="1" muted="1" src="/videos/' + item.letterCode + '"></video>');
            $('.submission.active .cbStatement').hide();
        } else {
            $('.submission.active .video').hide();
            $('.submission.active .cbStatement').show();
        }

    });

    if(tile.filter.name)
        $('#volatile_label').html(titleCaps(tile.filter.name) + '<br />' + (ti+1) + '/' + items.length);
    $('#volatile_room').text(room);
}

function doneTile() {
    $('body').attr('id', '').attr('class', '');
    $('#timeline').html('');
    $('#submissions').html('');
}

function interactiveTile() {
    if($('#tagcloud').css('display') != 'none')
        return;

    var largestFontSize = 40;
    var maxCount = 0;
    var keywords = [];

    $.get('/ongoingkeywords', function(data) {
        Object.keys(data.keywords).forEach(function(k) {
            var v = data.keywords[k].length;
            if(v <= 1)
                return;

            if(maxCount < v) maxCount = v;

            keywords.push({
                'text': k,
                'value': v
            });
        });

        keywords.forEach(function(k) {
            k.fontSize = Math.floor(largestFontSize * k.value/maxCount);
        });

        $.get('/mosaic/js/tiles/tagCloud.json', function(spec) {
            d3.select("#tagcloud").selectAll("*").remove();
            spec.data[0].values = keywords;
            vg.parse.spec(spec, function(chart) {
                var view = chart({
                  el: '#tagcloud',
                  renderer: 'svg'
                });
                
                view.update().on('click', function(e, i) {
                    $.post('/filters', {authorKeywords: [i.text], filterName: i.text, tile: tileId});
                });

                $('#loading').hide();
                $('#action').show().click(function() {
                    $('#action').hide();
                    $('#submissions').hide();
                    $('#tagcloud').show();
                });
            });
        });
    });
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
