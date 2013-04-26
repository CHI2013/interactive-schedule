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
    var row = Math.floor((Math.random()*2)); 

    if(allPhotos.length > 0 && lastPhotoAdded > 0)
        addItem(addPhoto(), row);
    
    if(allTweets.length > 0 && lastTweetAdded > 0)
        addItem(addTweet(), row^1);

    window.setTimeout(tick, 7*1000);
}

function getTweets() {
    console.log('Getting tweets...');

    $.getJSON('http://search.twitter.com/search.json?rpp=100&callback=?&q=%23chi2013', function(data) { 
        allTweets = data.results;
        lastTweetAdded = allTweets.length;
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
    tick();
});

function addTweet() {
    var tweet = allTweets[--lastTweetAdded];

    var html = $('<div class="item"><div class="tweet" id="tweet_' + tweet.id + '">' + 
        '<div class="userpic"><img src="' + tweet.profile_image_url + '" /></div>' + 
        '<div class="byline"><span class="name">' + tweet.from_user_name + '</span><br /><span class="username">@' + tweet.from_user + '</span><span class="date">' + relative_time(tweet.created_at) + '</span></div>' +
        '<div class="text">' + tweet.text + '</div></div></div>');

    shownTweets[tweet.id] = tweet;

    Object.keys(shownTweets).forEach(function(id) {
        var t = shownTweets[id];
        $('#tweet_' + id + ' .byline .date').text(relative_time(t.created_at));                
    }); 

    if(lastTweetAdded == 0)
        getTweets(); 

    return html; 
}

function addPhoto(i) {
    var photo = allPhotos[--lastPhotoAdded];
    while(photo.images[5].width < photo.images[5].height && lastPhotoAdded > 0)
        photo = allPhotos[--lastPhotoAdded];

    var html = $('<div class="photo item"><img src="' + photo.images[5].source + '" /></div>');

    if(lastPhotoAdded == 0)
        getPhotos(defaultUrl);  

    return html;
}

function addItem(html, container) {
    container = '#row-' + container;
    $(html).css('display', 'none');
    $(container).append(html);
    $(container + ' .item:first').fadeOut(150, function() {
        $(container + ' .item:last').fadeIn(150);
        $(this).remove();
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