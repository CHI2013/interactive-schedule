var maxTweets = 6;
var lastTweet;

function twitter() {
    var getTweets = function() {
        console.log('Getting tweets...');

        $.getJSON('http://search.twitter.com/search.json?rpp=100&callback=?&q=%23chi2013', function(data) {
            if(lastTweet != data.max_id) {
                for(var i = 0; i < maxTweets; i++) {
                    var r = data.results[i];
                    if(r.id <= lastTweet)
                        break;

                    var html = '<div class="tweet" style="display: none;" id="tweet_' + r.id + '">' + 
                    '<div class="userpic"><img src="' + r.profile_image_url + '" /></div>' + 
                    '<div class="byline"><span class="name">' + r.from_user_name + '</span> <span class="username">@' + r.from_user + '</span><span class="date">' + relative_time(r.created_at) + '</span></div>' +
                    '<div class="text">' + r.text + '</div></div>';

                    if(lastTweet)
                        $('#twitter').prepend(html);
                    else
                        $('#twitter').append(html)

                    $('#tweet_' + r.id).fadeIn();
                } 

                lastTweet = data.max_id;               
                $('.tweet:gt('+ maxTweets +')').remove();
            }

            // Update timestamps
            for(var i = 0; i < maxTweets; i++)
                $('#tweet_' + data.results[i].id + ' .byline .date').text(relative_time(data.results[i].created_at));                

            window.setTimeout(getTweets, 30*1000);
        });
    }

    getTweets();
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

$(document).ready(function() { twitter(); });