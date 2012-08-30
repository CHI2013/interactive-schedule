express = require 'express'
nano = require 'nano'

class GlanceServer
    constructor: () ->
        if process.argv[2]?
            @dbName = process.argv[2]
        else
            @dbName = 'chi2013'
        @app = @setupExpress()
        @connectCouchDB () =>
            @app.listen 8000
        @setupRest()
        
    setupExpress: () ->
        app = express()
        dir = __dirname + '/html'
        app.use express.static dir
        return app
        
    setupRest: () ->
        @app.get '/ongoingsessions', (req, res) =>
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
                    results = []
                    for row in body.rows
                        if row.value.start < clock and row.value.end > clock
                            results.push row.id
                    res.send results
        
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
        return [2012, 5, 9, 12, 0]

server = new GlanceServer()