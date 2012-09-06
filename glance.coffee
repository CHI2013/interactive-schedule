express = require 'express'
nano = require 'nano'
http = require 'http'
io = require 'socket.io'

class GlanceServer
    constructor: () ->
        @activeFilters = []
        @cells = ["A", "B", "C", "D", "E", "F"]
        
        if process.argv[2]?
            @dbName = process.argv[2]
        else
            @dbName = 'chi2013'
        @app = @setupExpress()
        @connectCouchDB () =>
            server = http.createServer @app
            server.listen 8000
            @iosocket = io.listen(server)
            @setupSocketIO()
        @setupRest()
    
    setupSocketIO: () ->
        @iosocket.sockets.on 'connection', (sock) =>
            console.log "Connection!"
        
    setupExpress: () ->
        app = express()
        app.use express.bodyParser()
        dir = __dirname + '/html'
        app.use express.static dir
        return app


    setupRest: () ->
        @app.get '/cell/:id', (req, res) =>
            for filter in @activeFilters
                console.log filter
                if req.params.id.toLowerCase() == filter.cell.toLowerCase()
                    res.send filter
                    return
            res.send {}
        
        @app.post '/filters', (req, res) =>
            if @cells.length == 0
                res.send {'status': 'error', 'message': 'No empty cells'}, 500
                return
            console.log @cells
            cell = @cells.pop()
            console.log cell
            tag = req.body.tag
            @getOngoingSessions (err, data) =>
                if err?
                    res.send {'status': 'error'}, 500
                else
                    sessionlist = []
                    for session in data
                        for sessiontag in session.tags
                            tag.toLowerCase()
                            if sessiontag.toLowerCase() == tag.toLowerCase()
                                sessionlist.push session.id
                                break
                    filter = {'tag': tag, 'sessions': sessionlist, 'timestamp': new Date(), 'cell': cell}
                    @activeFilters.push filter
                    res.send {'status': 'ok', 'cell': cell}
                    @iosocket.sockets.emit 'filtersUpdated', {}
        
        @app.get '/filters', (req, res) =>
            res.send @activeFilters
        
        @app.get '/ongoingsessions', (req, res) =>
            @getOngoingSessions (err, data) ->
                if err?
                    res.send('Could not load ongoing sessions', 500)
                else
                    res.send data
                    
        @app.get '/ongoingtags', (req, res) =>
            time = @getTime()
            from = [time[0], time[1], time[2]]
            to = [time[0], time[1], time[2]+1]
            clock = time[3]+":"+time[4]
            hour = ""+time[3]
            minute = ""+time[4]
            
            @db.view 'session', 'bydate', {"startkey": from, "endkey": to}, (err, body) ->
                if err?
                    console.log err
                else
                    tags = {}
                    count = 0
                    for row in body.rows
                        if row.value.start < clock and row.value.end > clock
                            if row.value.tags?
                                for tag in row.value.tags
                                    count++
                                    if tags[tag]?
                                        tags[tag].push row.value.id
                                    else
                                        tags[tag] = [row.value.id]
                    res.send {'tags': tags, 'totalItems': count}
            
        
    connectCouchDB: (cb) ->
        nano = nano 'http://localhost:5984'
        nano.db.get @dbName, (err, body) =>
            if err
                console.log "No " + @dbName +" database in CouchDB"
                process.exit 1
            else
                @db = nano.use @dbName
                console.log "Connected to CouchDB and opened the " + @dbName + " database."
                cb()
                
    getTime: () -> #This is just a stub
        return [2012, 5, 9, 12, 10]
        
        
    getOngoingSessions: (cb) ->
        time = @getTime()
        from = [time[0], time[1], time[2]]
        to = [time[0], time[1], time[2]+1]
        clock = time[3]+":"+time[4]
        hour = ""+time[3]
        minute = ""+time[4]

        @db.view 'session', 'bydate', {"startkey": from, "endkey": to}, (err, body) ->
            if err?
                cb err, null
            else
                results = []
                for row in body.rows
                    if row.value.start < clock and row.value.end > clock
                        results.push row.value
                cb null, results

server = new GlanceServer()