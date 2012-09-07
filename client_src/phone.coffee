root = exports ? window

$(document).ready () ->
    socket = io.connect "http://"+window.location.hostname, {port: 8000}
    socket.on 'filtersUpdated', (data) ->
        $.get '/filters', (data) ->
            console.log "Filters updated!"
            console.log data
    
    $.get '/ongoingsessions', (data) ->
        console.log "Ongoing sessions:"
        console.log data
        
    $.get '/ongoingtags', (data) ->
        console.log "Ongoing tags:"
        console.log data