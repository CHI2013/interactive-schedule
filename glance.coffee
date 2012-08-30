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
        
    setupExpress: () ->
        app = express()
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

server = new GlanceServer()