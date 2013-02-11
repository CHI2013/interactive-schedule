glanceHost = window.location.host

queryURL = (url) ->
    return '/'+url

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
        
asyncTest "Get tiles", 3, () ->
    $.getJSON queryURL('tiles'), (data) ->
        ok data?, "Got some data"
        ok Object.keys(data).length > 0, "Length of tiles are greater than zero"
        for key, tile of data
            $.getJSON queryURL('tiles/'+key), (data) ->
                ok data?, "It was possible to fetch a tile"
                start()
            break
        
asyncTest "Post a filter", 2, () ->
    query = {"authorKeywords":["visualization"]}
    post = $.post queryURL('filters'), query, (data) ->
        ok data?, "Got some data"
        $.getJSON queryURL('tiles/'+data.tileId), (data) ->
            ok (JSON.stringify data.filter.query) == (JSON.stringify query), "Tile updated with the proper filter"
            start()
    post.fail () ->
        start()
        ok false, "Request failed"
        
                
            
asyncTest "Post a filter with tile", 2, () ->
    query = {"authorKeywords":["visualization"], "tile":"G"}
    post = $.post queryURL('filters'), query, (data) ->
        ok data?, "Got some data"
        $.getJSON queryURL('tiles/G'), (data) ->
            start()
            delete query.tile
            ok (JSON.stringify data.filter.query) == (JSON.stringify query), "Tile updated with the proper filter"
    post.fail () ->
        start()
        ok false, "Request failed"

            
asyncTest "Post a filter with illegal tile", 2, () ->
    query = {"authorKeywords":["visualization"], "tile":"Z"}
    $.post queryURL('filters'), query, (data) ->
        ok data?, "Got some data"
        ok data.tileId != 'Z'
        start()
        
asyncTest "Post a filter with an unavailable tile", 2, () ->
    query = {"authorKeywords":["visualization"], "tile":"A"}
    $.post queryURL('filters'), query, (data) ->
        ok data?, "Got some data"
        ok data.tileId != 'A'
        start()
            
asyncTest "Get ongoing sessions", 3, () ->
    $.getJSON queryURL('ongoingSessions'), (data) ->
        ok data?, "Got some data"
        ok Object.keys(data.sessions).length > 0, "Length of ongoing sessions are greater than zero"
        for session in data.sessions
            ok session.submissions?, "Submissions have been inlined"
            break
        start()
        
asyncTest "Get ongoing submissions", 2, () ->
    $.getJSON queryURL('ongoingSubmissions'), (data) ->
        ok data?, "Got some data"
        ok Object.keys(data).length > 0, "Length of ongoing submissions are greater than zero"
        start()  