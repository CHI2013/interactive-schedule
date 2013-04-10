var allTweets = [];
var shownTweets = {};
var lastTweetAdded = 0;

var allPhotos = [];
var photosLastUpdated;
var defaultUrl = 'https://graph.facebook.com/301278083287279/photos';
var altUrl;
var lastPhotoAdded = 0;

function tick() {
    var pseudoCoinFlip = Math.floor((Math.random()*3));
    if(pseudoCoinFlip == 2 && allPhotos.length > 0)
        addPhoto(--lastPhotoAdded);
    else if(allTweets.length > 0)
        addTweet(--lastTweetAdded);

    window.setTimeout(tick, 3*1000);
}

function getTweets() {
    console.log('Getting tweets...');

    $.getJSON('http://search.twitter.com/search.json?rpp=100&callback=?&q=%23chi2013', function(data) { 
        allTweets = data.results;
        lastTweetAdded = allTweets.length;
        tick();
    });
}

function getPhotos(url) {
    console.log('Get photos...');
    $.getJSON(url, function(photos) {
        if(photosLastUpdated != photos.data[0].updated_time) {
            allPhotos = photos.data;
            lastPhotoAdded = allPhotos.length;
            photosLastUpdated = photos.data[0].updated_time;
            altUrl = photos.paging.next || photos.paging.previous;
        } else {
            getPhotos(altUrl);
        }
    });
}

$(document).ready(function() {
    getTweets();
    getPhotos(defaultUrl);
    // $('#social').isotope({
    //   // options
    //   itemSelector : '.item',
    //   masonryHorizontal: {
    //     rowHeight: 238
    //   },
    //   animationEngine: 'css',
    //   onLayout: function( $elems, instance ) {
    //     $elems.each(function(i) {
    //         if($(this).offset().top > 300)
    //             $(this).remove();
    //     })
    //   }
    // });
});

function addTweet(i) {
    var tweet = allTweets[i];

    var html = $('<div class="tweet item" id="tweet_' + tweet.id + '">' + 
        '<div class="userpic"><img src="' + tweet.profile_image_url + '" /></div>' + 
        '<div class="byline"><span class="name">' + tweet.from_user_name + '</span> <span class="username">@' + tweet.from_user + '</span><span class="date">' + relative_time(tweet.created_at) + '</span></div>' +
        '<div class="text">' + tweet.text + '</div></div>');

    addItem(html);

    shownTweets[tweet.id] = tweet;

    Object.keys(shownTweets).forEach(function(id) {
        var t = shownTweets[id];
        $('#tweet_' + id + ' .byline .date').text(relative_time(t.created_at));                
    }); 

    if(i == 0)
        getTweets();  
}

function addPhoto(i) {
    var photo = allPhotos[i];
    var which = Math.floor(Math.random()*2) + 5;

    var html = $('<img class="photo item" src="' + photo.images[which].source + '" />');
    addItem(html);

    if(i == 0)
        getPhotos(defaultUrl);  
}

function addItem(html) {
    $('#social').prepend(html)
        .freetile({
            animate: true, 
            elementDelay: 50,
            callback: function() {
                $('#social .item').each(function(i) {
                    var e = $(this), o = e.offset(), h = e.height(),
                        r = false;
                    
                    if(e.hasClass('tweet')) {
                        r = ((o.top + h) > 300);
                    } else {
                        r = (((300 - o.top) / h) < 0.33);
                    }

                    if(r)
                        e.fadeOut(200, function() {
                            $(this).remove();
                        })
                })
            }
        });
}

function relative_time(time_value) {
  var values = time_value.replace(',', '').split(" ");
  time_value = values[2] + " " + values[1] + ", " + values[3] + " " + values[4];
  var parsed_date = Date.parse(time_value);
  var relative_to = (arguments.length > 1) ? arguments[1] : new Date();
  var delta = parseInt((relative_to.getTime() - parsed_date) / 1000);
  delta = delta + (relative_to.getTimezoneOffset() * 60);

  if(delta < (60*60)) {
    return (parseInt(delta / 60)).toString() + 'm';
  } else if(delta < (24*60*60)) {
    return (parseInt(delta / 3600)).toString() + 'h';
  } else {
    return (parseInt(delta / 86400)).toString() + 'd';
  }
}