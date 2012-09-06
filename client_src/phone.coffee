root = exports ? window

$(document).ready () ->
    socket = io.connect "http://"+window.location.hostname, {port: 8000}
    socket.on 'filtersUpdated', (data) ->
        $.get '/filters', (data) ->
            console.log data
    
    $.get '/ongoingsessions', (data) ->
        console.log data
        
    $.get '/ongoingtags', (data) ->
        console.log data