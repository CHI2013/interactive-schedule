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

    var animateNext = function() {
        var $target = $('.submission:eq(' + itemIndex + ')')
        $target.addClass('active').show().css({
            left: $target.width()+100
        }).animate({
            left: 0
        }, 500, 'easeOutBack', function() {
            if(item.hasVideo && item.letterCode) {
                $('.submission.active .video').html('<video height="100%" autoplay="1" muted="1" src="/videos/' + item.letterCode + '"></video>');
                $('.submission.active .cbStatement').hide();
            } else {
                $('.submission.active .video').hide();
                $('.submission.active .cbStatement').show();
            }

        });
    }

    if($('.submission.active').length > 0) {
        $('.submission.active').each(function(index, self) {
            $('.submission.active .video').html('');

            var $this = $(this);
            $this.removeClass('active').animate({
                left: -($this.width())-100,
            }, 500, 'easeInBack', function() {
                animateNext();
            });
        });
    } else {
        animateNext();
    }  
    

    if(tile.filter.name)
        $('#volatile_label').html(titleCaps(tile.filter.name) + '<br />' + (ti+1) + '/' + items.length);
    $('#volatile_room').text(room);
}

function doneTile() {
    $('body').attr('id', '').attr('class', '');
    $('#timeline').html('');
    $('#submissions').html('');
}

var topOffset = parseInt(getURLParameter('top'));
var leftOffset = parseInt(getURLParameter('left'));

var hovered = {};

var tagCloudTimeStamp;

function checkHover() {
    var now = new Date();
    if (tagCloudTimeStamp != undefined && (now.getTime() - tagCloudTimeStamp.getTime()) > 2500) {
        $('#tagcloud').hide();
        $('#action').show();
        $('#submissions').show();
        return;
    }
    for (var hover in hovered) {
        if (hovered.hasOwnProperty(hover)) {
            text = $(hovered[hover].elem).text();
            if((now.getTime() - hovered[hover].timestamp.getTime()) > 20) {
                $(hovered[hover].elem).css("fill", "#ccc");
                delete hovered[hover];
            } else if (hovered[hover] != undefined && !hovered[hover].posted && hovered[hover].timestamp.getTime() - hovered[hover].startTime.getTime() > 1500) {
                console.log("Posting to filters", text, tileId);
                hovered[hover].posted = true;
               // $.post('/filters', {authorKeywords: [text], filterName: text, tile: tileId});
            }
          }
    };
}



function handleFingerInput(data) {
    if (data.x < leftOffset || data.x > leftOffset + 540) {
        return;
    }
    if (data.y < topOffset || data.y > topOffset + 405) {
        return;
    }
    
    $('#action').hide();
    
    if (!$('#tagcloud').is(':visible')) {
        $('#action').hide();
        $('#tagcloud').show();
    }
    tagCloudTimeStamp = new Date();
    //data.id, data.x, data.y
    d3.selectAll("text").html(function(d, i) {
        boundingBox = this.getBBox();
        bbLeft = leftOffset + $('#tagcloud').offset().left + boundingBox.x
        bbTop = topOffset + $('#tagcloud').offset().top + boundingBox.y
        bbWidth = boundingBox.width;
        bbHeight = boundingBox.height;
        if (inside(data.x, data.y, bbLeft, bbTop, bbWidth, bbHeight)) {
            keyword = $(this).text();
            if (hovered[keyword] == undefined) {
                hovered[keyword] = {};
                hovered[keyword].posted = false;
                hovered[keyword].elem = this;
                hovered[keyword].count = 0;
                hovered[keyword].startTime = new Date();
                $(this).css("fill", "#ff0000");
            } else {
                hovered[keyword].count++;
            }
            hovered[keyword].timestamp = new Date();
        }
    });
}

function inside(x, y, left, top, width, height) {
    if (x+1 < left || x-1 > left + width) {
        return false;
    }
    if (y+1 < top || y-1 > top + height) {
        return false;
    }
    return true;
}

function interactiveTile() {
    window.setInterval(checkHover, 100);
    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });
    
    socket.on('finger', function(data) {
        handleFingerInput(data);
    });
    
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

function getURLParameter(name) {
  href = window.location.href;
  split = href.split('?');
  if (split.length > 0) {
      search = '?'+split[1];
      return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(search)||[,""])[1].replace(/\+/g, '%20'))||null
  } else {
      return null;
  }
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
