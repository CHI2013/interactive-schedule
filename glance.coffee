express = require 'express'
nano = require 'nano'
http = require 'http'
io = require 'socket.io'
s = require 'searchjs'
fs = require 'fs'
_ = require 'underscore'

class GlanceServer
    constructor: () ->
        @tiles = {}
        @tickCount = 0
        @availableTiles = []
        @dbName = ""
        @config = {}
        @tickIndex = {}
        
        @loadConfig () =>
            @setupTiles()
            @dbName = @config.db
            @app = @setupExpress()
            @connectCouchDB () =>
                server = http.createServer @app
                server.listen @config.port
                @iosocket = io.listen(server)
                @setupSocketIO()
                @setupRest()
                
                sendTickWrapper = () => #Ugly scoping hack
                    @sendTick()
                setInterval sendTickWrapper, @config.tickFrequency
    
    loadConfig: (cb) ->
        if process.argv[2]?
            filename = process.argv[2]
            fs.readFile filename, (err, data) =>
                if err?
                    console.log err
                    process.exit 1
                @config = JSON.parse data
                cb()
        else
            console.log "No config file provided!"
            process.exit 1
                    
    setupTiles: () ->
        if not @config.tiles?
            console.log "No tiles defined in config!"
            process.exit 1
        @tiles = @config.tiles
        for tile, val of @tiles
            if val.type == 'filter'
                @availableTiles.push tile            

    cleanTile: (tileId) ->
        delete @tiles[tileId]['filter']
        delete @tiles[tileId]['timestamp']
        delete @tiles[tileId]['total']
        @availableTiles.push tileId            
    
    setupSocketIO: () ->
        @iosocket.sockets.on 'connection', (sock) =>
            console.log "Connection!"
            
    sendTick: () ->
        for tileId, i of @tickIndex
            @tickIndex[tileId] = ++i
            if(@tickIndex[tileId] >= @tiles[tileId]['total'])
                @iosocket.sockets.emit 'doneTile', {'tileId': tileId}
                @cleanTile(tileId)
                delete @tickIndex[tileId]

        @iosocket.sockets.emit 'tick', @tickIndex
        @tickCount++
        
    setupExpress: () ->
        app = express()
        app.use express.bodyParser()
        dir = __dirname + '/html'
        app.use express.static dir
        return app
        
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

    ###
    Given a query this method will return a tile.
    If the query provides a tile (that is available) this will be used.
    Note that the tile key on the query will be removed from the query as a sideeffect!
    ###
    getTile: (query) ->
        if query.tile?
            found = false
            newAvailableTiles = []
            for tile in @availableTiles
                if tile == query.tile
                    found = true
                    tileId = query.tile
                else
                    newAvailableTiles.push tile
            @availableTiles = newAvailableTiles
            if not found
                tileId = @availableTiles.pop()
            delete query.tile
        else
            tileId = @availableTiles.pop()
        return tileId
    
    setupRest: () ->
        #Get the filter of a given tile (e.g. F)
        @app.get '/tiles/:id', (req, res) =>
            if not @tiles[req.params.id]?
                res.jsonp {'status': 'error', 'message': 'No such tile'}, 400
                return
            res.jsonp @tiles[req.params.id]
            
        @app.get '/tiles', (req, res) =>
            res.jsonp @tiles
        
        #Apply a new filter. The content of the post is a tag. A tile-id will be popped from @availableTiles and the filter will be applied on the given tile.
        #IF the query contains a named tile this will be used IF it is available, otherwise it will be given another tile.
        @app.post '/filters', (req, res) =>
            if @availableTiles.length == 0
                res.jsonp {'status': 'error', 'message': 'No empty tiles'}, 500
                return
            
            query = req.body
            tileId = @getTile query
            
            @getOngoingSubmissions (err, data) =>
                if err?
                    res.jsonp {'status': 'error', 'message': err}, 500
                else
                    matches = s.matchArray data, query
                    filter = {'query': query, 'submissions': matches, 'tileId': tileId}
                    @tiles[tileId]['filter'] = filter
                    @tiles[tileId]['timestamp'] = new Date()
                    @tiles[tileId]['total'] = matches.length
                    @tickIndex[tileId] = -1
                    res.jsonp {'status': 'ok', 'tileId': tileId}
                    @iosocket.sockets.emit 'tilesUpdated', {}
                    @iosocket.sockets.emit 'newTile', {'tileId': tileId}
        
        #Returns a list of all sessions
        @app.get '/submission', (req, res) =>
            @db.view 'submission', 'all', (err, body) =>
                if err?
                    res.send 'Could not load submissions', 500
                    return
                res.jsonp body.rows
                
        #Returns a specific submission with a given ID
        @app.get '/submission/:id', (req, res) =>
            @db.get req.params.id, (err, body) ->
                if err?
                    res.send 'Could not load given submission', 500
                else
                    if not body.type?
                        res.send 'No submission with given id', 404
                        return
                    if body.type != 'submission'
                        res.send 'No submission with given id', 404
                    else
                        res.jsonp body
                        
                        
        #Redirects to the vdeo of a specific submission with a given ID
        @app.get '/submission/:id/video', (req, res) =>
            @db.get req.params.id, (err, body) =>
                if err?
                    res.send 'Could not load given submission', 500
                else
                    if not body.type?
                        res.send 'No submission with given id', 404
                        return
                    if body.type != 'submission'
                        res.send 'No submission with given id', 404
                    else
                        if body.videoPreviewFile?
                            res.redirect(@config.videoDir + '/' + body.videoPreviewFile);
                        else
                            res.send 'No video for submission', 404

        
        #Returns a list of all days
        @app.get '/day', (req, res) =>
            @db.view 'day', 'all', (err, body) =>
                if err?
                    res.send 'Could not load days', 500
                    return
                res.jsonp body.rows
                
        #Returns a specific day with a given ID
        @app.get '/day/:id', (req, res) =>
            @db.get req.params.id, (err, body) ->
                if err?
                    res.send 'Could not load given day', 500
                else
                    if not body.type?
                        res.send 'No day with given id', 404
                        return
                    if body.type != 'day'
                        res.send 'No day with given id', 404
                    else
                        res.jsonp body
                        
        #Returns a list of all timeslots
        @app.get '/timeslot', (req, res) =>
            @db.view 'timeslot', 'all', (err, body) =>
                if err?
                    res.send 'Could not load days', 500
                    return
                res.jsonp body.rows

        #Returns a specific timeslot with a given ID
        @app.get '/timeslot/:id', (req, res) =>
            @db.get req.params.id, (err, body) ->
                if err?
                    res.send 'Could not load given timeslot', 500
                else
                    if not body.type?
                        res.send 'No timeslot with given id', 404
                        return
                    if body.type != 'timeslot'
                        res.send 'No timeslot with given id', 404
                    else
                        res.jsonp body
        
        #Returns a list of all sessions
        @app.get '/session', (req, res) =>
            @db.view 'session', 'all', (err, body) =>
                if err?
                    res.send 'Could not load sessions', 500
                    return
                res.jsonp body.rows
                
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
                        res.jsonp body
                        
        #Return the orientation of the large display
        @app.get '/orientation', (req, res) =>
            res.jsonp {'orientation': @config.orientation}
        
##################################
##More specialized queries below##
##################################
        
        #Returns a list of all ongoing sessions
        @app.get '/ongoingsubmissions', (req, res) =>
            @getOngoingSubmissions (err, data) ->
                if err?
                    res.send 'Could not load ongoing submissions', 500
                else
                    res.jsonp data

        #Returns a list of all ongoing sessions
        @app.get '/ongoingsessions', (req, res) =>
            @getOngoingSessions (err, data) ->
                if err?
                    res.send 'Could not load ongoing sessions', 500
                else
                    res.jsonp data

        #Returns a list of all tags of ongoing submissions each tag has a list of submissions matching that tag. 
        #Also a count of all ongoing submissions is returned (which can be used e.g. to size tags in a tag cloud)
        @app.get '/ongoingtags', (req, res) =>
            @getOngoingSubmissions (err, data) ->
                if err?
                    res.send 'Could not load ongoing sessions', 500
                else
                    tags = {}
                    count = 0
                    for submission in data
                        if submission.tags?
                            for tag in submission.tags
                                count++
                                if tags[tag]?
                                    tags[tag].push submission._id
                                else
                                    tags[tag] = [submission._id]
                    res.jsonp {'tags': tags, 'totalItems': count}
                    

        #Returns a list of all keywords of ongoing submissions each keyword has a list of keywords matching that tag. 
        #Also a count of all ongoing submissions is returned (which can be used e.g. to size keywords in a tag cloud)
        @app.get '/ongoingkeywords', (req, res) =>
            @getOngoingSubmissions (err, data) ->
                if err?
                    res.send 'Could not load ongoing sessions', 500
                else
                    keywords = {}
                    count = 0
                    for submission in data
                        console.log submission.authorKeywords
                        if submission.authorKeywords?
                            for keyword in submission.authorKeywords
                                count++
                                if keywords[keyword]?
                                    keywords[keyword].push submission._id
                                else
                                    keywords[keyword] = [submission._id]
                    res.jsonp {'keywords': keywords, 'totalItems': count}
  
        
        #Returns the ongoing timeslot (if any)
        @app.get '/currentTimeSlot', (req, res) =>
            @getCurrentTimeSlot (error, doc) =>
                if error?
                    res.send "Could not load current timeslot", 500
                else
                    if not doc?
                        res.send "No ongoing timeslot", 404
                    else
                        res.jsonp doc
    
    #This is a stub method that just returns a time where there is sessions ongoing in the dataset.            
    getTime: () -> #This is just a stub
        if @config.fixedTime? 
            return @config.fixedTime
        date = new Date()
        return [date.getFullYear(), date.getMonth(), date.getDay(), date.getHours(), date.getMinutes()]
        
    getCurrentTimeSlot: (cb) ->
        time = @getTime()
        start = time[..2]
        end = time[..2]
        @db.view 'day', 'bydate', {"startkey": start, "endkey": end}, (err, body) =>
        #@db.view 'day', 'all', (err, body) =>    
            if err?
                cb err, null
            else
                dayNo = -1
                currentDay = null
                count = 0
                for row in body.rows
                    day = row.value
                    if _.difference(day.date, start).length == 0
                        dayNo = count
                        currentDay = day
                    count++
                if body.rows.length != 1
                    cb new Error "No data for given time", null
                else
                    day = body.rows[0].value
                    @db.fetch {'keys': day.timeslots}, (err, body) ->
                        if err?
                            cb err, null
                        else
                            for timeslot in body.rows
                                if timeslot.doc.start[0] <= time[3] && timeslot.doc.end[0] >= time[3]
                                    cb null, timeslot.doc
                                    return
                            cb null, null
    
    inlineSubmissionsForSession: (session, cb) ->
        @db.fetch {"keys": session.submissions}, (err, submissions) =>
            if err?
                cb err
            submissionDocs = []
            for submission in submissions.rows
                if submission.error?
                    continue                                
                submissionDocs.push submission.doc
            session.submissions = submissionDocs
            cb null
            
    inlineSubmissionsForSessions: (sessions, count, cb) ->
        if count == sessions.length
            cb()
            return
        @inlineSubmissionsForSession sessions[count], (err) =>
            count++
            @inlineSubmissionsForSessions sessions, count, () =>
                cb()
                
    getOngoingSessions: (cb) ->
        @getCurrentTimeSlot (error, doc) =>
            if error?
                cb error, null
            else
                if not doc?
                    cb new Error "No data for given time", null
                else
                    @db.fetch {'keys': doc.sessions}, (err, body) =>
                        if err?
                            cb err, null
                        else
                            result = body.rows.map (row) -> row.doc
                            @inlineSubmissionsForSessions result, 0, () =>
                                cb null, result
                
    getOngoingSubmissions: (cb) ->
        @getOngoingSessions (err, sessions) =>
            if err?
                cb err, null
            else
                submissions = []
                for session in sessions
                    for submission in session.submissions
                        submissions.push submission
                cb null, submissions

server = new GlanceServer()