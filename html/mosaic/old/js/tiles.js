var slideShows = {};

var svgSizes = {
    height:        7, 
    sigWidth:    155,
    courseWidth: 155,
    panelWidth:  155,
    paperWidth:   35,
    noteWidth:    15,
    altchiWidth:  20,
    padding:       5,
    roundRect:     3,

    pinRad:        5,
    progressRad:  10,
};

var roomLoc = {
    '241': [320, 276],
    '242': [320, 222],
    '243': [295, 143],
    '251': [160, 286],
    '252': [160, 236],
    '253': [120, 152],

    '342': [480, 198],
    '343': [460, 127],
    '361': [430,  55],
    '363': [410,  20],
    '351': [0,   263],
    '352': [0,   212],

    'Bordeaux': [480, 320],
    'Bleu':     [240,  70],
    'Havane':   [0,   320]
};

$(document).ready(function() {
    $('#map').svg({ onLoad: drawLozenges });
    showTagCloud();
    // synchSlideshow();

    var socket;
    socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });

    socket.on('tick', function(count) {
        synchSlideshow();
    });

    var getTiles = function() {
        return $.get('/tiles', function(data) {
            for(tileId in data) {
                if(data[tileId].filter)
                    addFilter(data[tileId].filter);
            } 
        });
    }

    socket.on('tilesUpdated', function(data) {
        getTiles();
    });

    getTiles();
})

function showTagCloud() {
    var tagCloudHtml = '<div id="htmltagcloud"> <span id="0" class="wrd tagcloud3">acm</span> <span id="1" class="wrd tagcloud0">addressing</span> <span id="9" class="wrd tagcloud7">conference</span> <span id="10" class="wrd tagcloud3">constantly</span> <span id="6" class="wrd tagcloud10"><a href="#" onclick="addFilter($(this).parent().parent().parent().attr(\'id\'), \'crowdsourcing\');">crowdsourcing</a></span> <span id="11" class="wrd tagcloud3">culture</span> <span id="12" class="wrd tagcloud6"><a href="#" onclick="addFilter($(this).parent().parent().parent().attr(\'id\'), \'design\');">design</a></span> <span id="13" class="wrd tagcloud5">different</span> <span id="14" class="wrd tagcloud5">diverse</span> <span id="15" class="wrd tagcloud3">draw</span> <span id="22" class="wrd tagcloud0"><a href="#" onclick="addFilter($(this).parent().parent().parent().attr(\'id\'), \'education\');">education</a></span> <span id="19" class="wrd tagcloud3"><a href="#" onclick="addFilter($(this).parent().parent().parent().attr(\'id\'), \'environment\');">environment</a></span> <span id="16" class="wrd tagcloud5">engineering</span> <span id="17" class="wrd tagcloud3">europe</span> <span id="18" class="wrd tagcloud3">experience</span> <span id="20" class="wrd tagcloud5">france</span> <span id="21" class="wrd tagcloud0">games</span> <span id="22" class="wrd tagcloud0">hci</span> <span id="19" class="wrd tagcloud3"><a href="#" onclick="addFilter($(this).parent().parent().parent().attr(\'id\'), \'health\');">health</a></span> <span id="23" class="wrd tagcloud3">human-computer</span> <span id="24" class="wrd tagcloud5">innovative</span> <span id="25" class="wrd tagcloud5">interaction</span> <span id="26" class="wrd tagcloud0">light</span> <span id="27" class="wrd tagcloud3">management</span> <span id="28" class="wrd tagcloud0">multidisciplinary</span> <span id="29" class="wrd tagcloud3">news</span> <span id="30" class="wrd tagcloud3">offering</span> <span id="31" class="wrd tagcloud7">page</span> <span id="32" class="wrd tagcloud6">paris</span> <span id="33" class="wrd tagcloud3">people</span> <span id="34" class="wrd tagcloud7">perspectives</span> <span id="35" class="wrd tagcloud3">professor</span> <span id="36" class="wrd tagcloud3">program</span> <span id="37" class="wrd tagcloud3">recent</span> <span id="38" class="wrd tagcloud6">research</span>  <span id="40" class="wrd tagcloud0">serve</span> <span id="41" class="wrd tagcloud3">sigchi</span> <span id="43" class="wrd tagcloud0">spirit</span> <span id="44" class="wrd tagcloud3">students</span> <span id="45" class="wrd tagcloud3">system</span> <span id="46" class="wrd tagcloud3">technical</span> <span id="47" class="wrd tagcloud3">technology</span> <span id="48" class="wrd tagcloud3">user</span> <span id="6" class="wrd tagcloud10"><a href="#" onclick="addFilter($(this).parent().parent().parent().attr(\'id\'), \'visualization\');">visualization</a></span> <span id="49" class="wrd tagcloud5">welcome</span> </div>'; 
    if($('#htmltagcloud').length > 0) return;
    if($('.blank').length == 0) return;
    
    var rand = Math.floor((Math.random()*$('.blank').length));
    $($('.blank')[rand]).html(tagCloudHtml);
}

function drawLozenges(svg) {
    for(var room in roomLoc) {
        var s = schedule[room];
        
        var g = svg.group({ transform: 'translate(' + roomLoc[room][0] + ' ' + roomLoc[room][1] + ')', id: 'room-' + room });
        var x = 0;

        for(var i in s) {
            var item = s[i];
            var w    = svgSizes[item + 'Width'];
            var h    = svgSizes['height'];
            var r    = svgSizes['roundRect'];
            var p    = svgSizes['padding'];

            svg.rect(g, x, 0, w, h, r, r, {'class': 'lozenge'});
            
                svg.rect(g, x+02, 9.5, 6, 8, r, r, {'class': 'filterD pin'});
                svg.rect(g, x+08, 9.5, 6, 8, r, r, {'class': 'filterE pin'});
                svg.rect(g, x+02, 19, 6, 8, r, r, {'class': 'filterF pin'});
            if(item == 'paper') { 
                svg.rect(g, x+14, 9.5, 6, 8, r, r, {'class': 'filterG pin'});
                svg.rect(g, x+20, 9.5, 6, 8, r, r, {'class': 'filterH pin'});
                svg.rect(g, x+26, 9.5, 6, 8, r, r, {'class': 'filterI pin'});
                // svg.rect(g, x+02, 9.5, 6, 7, r, r, {'class': 'filter6 pin'});
            }

            x += w + p;
        }               
    }
}

function addFilter(filterTile) {
    console.log(filterTile);
    var tileId = filterTile.tile;

    $('svg .pin.filter' + tileId).show();

    var cellId = '#filter' + tileId;
    
    $(cellId).removeClass('blank').html('<div class="content"></div>');
    var content = $(cellId).children('.content'); 
    
    // for(var i = 0; i < filtersData.length; i++)
    //     if(filtersData[i].filter.toLowerCase() == filterName.toLowerCase())
    //     { filter = filtersData[i]; break; }
            
    var html  = '<h2>' + titleCaps(filterTile.query.tags.join(' & ')) + '</h2>';
    html     += '<div class="slideshow"><div class="title info"><div class="inner">';
    for(var i = 0; i < filterTile.submissions.length; i++)
        html += '<h5>' + filterTile.submissions[i].title + '</h5>';
    html    += '</div></div>';

    for(var i = 0; i < filterTile.submissions.length; i++) {
        var item = filterTile.submissions[i];
        html += '<div class="info"><div class="inner">';
        html += '<h3>' + item.title + '</h3>';
        html += '<h4>' + item.authors.join(', ') + '</h4>';
        // html += '<h5>' + item.affiliation + '</h4>';
        html += '</div></div>';
    }
    
    html     += '</div>';
    
    html     += '<svg class="progress_bar" width="' + tile.width + '" height="20">';
    var cxCenter = (tile.width-40*filterTile.submissions.length)/2;
    for(var i = 0, cx = cxCenter; i < filterTile.submissions.length; i++, cx+=50)
        html += '<circle r="10" cx="' + cx + '" cy="10"></circle>';            
    html     += '</svg>';
    
    content.html(html);
    content.after('<div class="video"><div id="' + cellId + '_video" style="display: none;" width="' + tile.width + '" height="' + tile.height + '"></div></div>');
    
    var slideshow = $(cellId + ' .content .slideshow').slideshow({
        duration: 400,
        delay: 23000,
        selector: '> div',
        transition: 'push(left)',
        autoPlay: false,
        show: function (e, params){
            var currIndex = params.next.index - 1;
            var nextElm = params.next.element;
            var content = nextElm.parent().parent();

            if(params.next.index == 0) {
                delete slideShows[cellId];
                content.fadeOut(500, function() {
                    content.parent().addClass('blank'); 
                    $('svg .' + tileId).hide();
                    
                    showTagCloud();
                })
            } else {
                jwplayer(cellId + '_video').setup({
                    'flashplayer': 'jwplayer/player.swf',
                    'id': cellId + '_video',
                    'width': tile.width,
                    'height': tile.height,
                    'file': '/videos/' + filterTile.submissions[currIndex].video + '.mp4',
                    mute: true,
                    controlbar: "none",
                    duration: 15
                  });
                $(cellId + ' .video').hide();
            }
                
            nextElm.parent().next('svg').children('circle').removeClass('current');
            nextElm.parent().next('svg').children('circle:eq(' + (params.next.index - 1) + ')').addClass('current');
        }
    });
    
    slideshow.slideshow('show', 0);
    slideShows[cellId] = slideshow;
    
    // showTagCloud();
}

function synchSlideshow() {
    console.log('syncSlideshow');
    $('.pin-large').hide();
    
    for(var id in slideShows) {
        slideShows[id].slideshow('show', 'next');
        var curr = $(id + ' .content .slideshow').data('slideshow').current;
        $(id + '-' + curr).show();
    }
        
    window.setTimeout(function() {
        console.log('showVideo');
        
        for(var id in slideShows) {                        
            if($(id + ' .content .slideshow').data('slideshow').current == 0)
                continue;

            jwplayer(id + '_video').play(true);
            $(id + ' .content').fadeOut(250, function() {
                $(this).next('.video').fadeIn(250);
            });
        }
            
        window.setTimeout(function() {
            console.log('showTitle');
            
            for(var id in slideShows) {                        
                if($(id + ' .content .slideshow').data('slideshow').current == 0)
                    continue;

                jwplayer(id + '_video').stop();
                $(id + ' .video').fadeOut(250, function() {
                    $(this).prev('.content').fadeIn(250);
                });
            }
            
            // window.setTimeout(synchSlideshow, 3000);
        }, 15000);
    }, 5000);    
    
}

var tweet = 0;
var twitter = setInterval(twitterFn, Math.floor((Math.random()*7)+1) * 1000);
function twitterFn() {
    $('div.tweet:eq(' + (tweet++) + ')').fadeIn();
    clearInterval(twitter);
    twitter = setInterval(twitterFn, Math.floor((Math.random()*7)+1) * 1000);
}