root = exports ? window

$(document).ready () ->
    socket = io.connect "http://"+window.location.hostname, {port: 8000}
    socket.on 'tilesUpdated', (data) ->
        $.get '/tiles', (data) ->
            console.log "Filters updated!"
            console.log data
            
    socket.on 'tick', (data) ->
        console.log "Tick"
    
    $.get '/ongoingsessions', (data) ->
        console.log "Ongoing sessions:"
        console.log data
        
    $.get '/ongoingtags', (data) ->
        console.log "Ongoing tags:"
        console.log data