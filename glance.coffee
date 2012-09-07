express = require 'express'
nano = require 'nano'
http = require 'http'
io = require 'socket.io'
s = require 'searchjs'

class GlanceServer
    constructor: () ->
        @activeFilters = [] #Filters that are currently on display
        @cells = ["A", "B", "C", "D", "E", "F"] #Cell-ids not in use. When a filter is applied one of these is popped
        
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
        #Get the filter of a given cell (e.g. F)
        @app.get '/cell/:id', (req, res) =>
            for filter in @activeFilters
                if req.params.id.toLowerCase() == filter.cell.toLowerCase()
                    res.send filter
                    return
            res.send {}
        
        #Apply a new filter. The content of the post is a tag. A cell-id will be popped from @cells and the filter will be applied on the given cell.
        @app.post '/filters', (req, res) =>
            if @cells.length == 0
                res.send {'status': 'error', 'message': 'No empty cells'}, 500
                return
            cell = @cells.pop()
            console.log cell
            query = req.body
            console.log query
            @getOngoingSessions (err, data) =>
                if err?
                    res.send {'status': 'error'}, 500
                else
                    matches = s.matchArray data, query
                    filter = {'query': query, 'sessions': matches, 'timestamp': new Date(), 'cell': cell}
                    @activeFilters.push filter
                    res.send {'status': 'ok', 'cell': cell}
                    @iosocket.sockets.emit 'filtersUpdated', {}
        
        #Get all active filters
        @app.get '/filters', (req, res) =>
            res.send @activeFilters
        
        
        #Returns a list of all ongoing sessions
        @app.get '/ongoingsessions', (req, res) =>
            @getOngoingSessions (err, data) ->
                if err?
                    res.send 'Could not load ongoing sessions', 500
                else
                    res.send data
        
        #Returns a list of all sessions
        @app.get '/session', (req, res) =>
            @db.view 'session', 'all', (err, body) =>
                if err?
                    res.send 'Could not load sessions', 500
                    return
                res.send body.rows
                
        #Returns a specific session with a given ID
        @app.get '/session/:id', (req, res) =>
            @db.get req.params.id, (err, body) ->
                if err?
                    res.send 'Could not load given session', 500
                else
                    if not body.type?
                        res.send 'No session with given id', 404
                        return
                    if body.type != 'session'
                        res.send 'No session with given id', 404
                    else
                        res.send body
        
        #Returns a list of all tags of ongoing sessions each tag has a list of sessions matching that tag. Also a count of all ongoing sessions is returned (which can be used e.g. to size tags in a tag cloud)
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
    
    #This is a stub method that just returns a time where there is sessions ongoing in the dataset.            
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
                    if row.value.Time < clock and row.value["End Time"] > clock
                        results.push row.value
                cb null, results

server = new GlanceServer()