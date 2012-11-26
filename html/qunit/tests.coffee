glanceHost = "localhost:8000"

queryURL = (url) ->
    if (window.location.host == glanceHost)
        return '/'+url;
    else
	    #cross-site request => use JSONP
        return 'http://'+glanceHost+'/'+url+'?callback=?'

asyncTest "Get days", 2, () ->
    $.getJSON queryURL('day'), (data) ->
        ok data?, "Got some data"
        ok data.length == 6, "Five days in the conference"
        start()
        
asyncTest "Get timelots", 2, () ->
    $.getJSON queryURL('timeslot'), (data) ->
        ok data?, "Got some data"
        ok data.length > 0, "Length of timeslots are greater than zero"
        start()
        
asyncTest "Get sessions", 2, () ->
    $.getJSON queryURL('session'), (data) ->
        ok data?, "Got some data"
        ok data.length > 0, "Length of sessions are greater than zero"
        start()
        
asyncTest "Get submissons", 2, () ->
    $.getJSON queryURL('submission'), (data) ->
        ok data?, "Got some data"
        ok data.length > 0, "Length of submissons are greater than zero"
        start()
        
asyncTest "Get tiles", 2, () ->
    $.getJSON queryURL('tiles'), (data) ->
        ok data?, "Got some data"
        ok Object.keys(data).length > 0, "Length of tiles are greater than zero"
        start()
        
asyncTest "Post a filter", 2, () ->
    query = {"tag":["visualization"]}
    $.post queryURL('filters'), query, (data) ->
        ok data?, "Got some data"
        $.getJSON queryURL('tiles/'+data.tileId), (data) ->
            ok JSON.stringify data.filter.query == JSON.stringify query, "Tile updated with the proper filter"
            start()