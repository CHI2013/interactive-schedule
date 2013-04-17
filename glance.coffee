express = require 'express'
nano = require 'nano'
http = require 'http'
io = require 'socket.io'
s = require 'searchjs'
fs = require 'fs'
_ = require 'underscore'
expressWinston = require 'express-winston'
winston = require 'winston'

class GlanceServer
    constructor: () ->
        @transports = [
              new winston.transports.File {
                  filename: 'glance.log',
                  timestamp: true
                  },
            new winston.transports.Console {
                  colorize: true,
                  timestamp: true
                } 
            ]
        
        @logger = new winston.Logger {
            'transports': @transports 
        }
        
        
        @tiles = {}
        @tickCount = 0
        @availableTiles = []
        @dbName = ""
        @config = {}
        @tickIndex = {}
        @autoCompleteList = undefined
        
        @currentTimeslot = null;
        
        @loadConfig () =>
            @dbName = @config.db
            @app = @setupExpress()
            @connectCouchDB () =>
                server = http.createServer @app
                server.listen @config.port
                @iosocket = io.listen server, {log: false}
                @setupSocketIO()
                @setupRest()
                @setupTiles () =>
                    tickWrapper = () => #Ugly scoping hack
                        @tick()
                    setInterval tickWrapper, @config.tickFrequency
    
    loadConfig: (cb) ->
        if process.argv[2]?
            filename = process.argv[2]
            fs.readFile filename, (err, data) =>
                if err?
                    @logger.error err
                    process.exit 1
                @config = JSON.parse data
                @logger.info "Configuration file loaded"
                if @config.fixedTime?
                    @logger.warn "Fixed time defined in config, use only for debug!"
                cb()
        else
            @logger.error "No config file provided!"
            process.exit 1
                    
    setupTiles: (cb) ->
        if not @config.sessionTiles? or not @config.breakTiles?
            @logger.error "No tiles defined in config!"
            process.exit 1
        @getCurrentTimeSlot (error, timeslot) =>
            if timeslot?
                @currentTimeslot = timeslot._id 
            if @currentTimeslot?
                tileSetup = _.clone @config.sessionTiles
            else
                tileSetup  = _.clone @config.breakTiles
            
            @getOngoingSubmissions (err1, ongoingSubmissions) =>
                for tile, val of tileSetup
                    @tiles[tile] = {}
                    @tiles[tile].type = val.type
                    @tiles[tile].when = val.when
                    if val.type == 'filter'
                        if val.filter?
                            filter = _.clone val.filter
                            if not err?
                                data = ongoingSubmissions.submissions
                                if filter?
                                    @filterSubmissions tile, filter, data
                        else
                            @availableTiles.push tile
                    else
                        @tile[tile] = val
                    @iosocket.sockets.emit 'newTile', {'tileId': tile}
                cb()


    cleanTile: (tileId) ->
        delete @tiles[tileId]['filter']
        delete @tiles[tileId]['timestamp']
        delete @tiles[tileId]['total']
        delete @tiles[tileId]['volatile']
        @availableTiles.push tileId            
    
    setupSocketIO: () ->
        @iosocket.sockets.on 'connection', (sock) =>
            @logger.info "Client connected", {'id': sock.id, 'clientIp': sock.handshake.address.address}
            
            sock.on 'disconnect', () =>
                @logger.info "Client disconnected", {'id': sock.id, 'clientIp': sock.handshake.address.address}
            
            
    tick: () ->
        for tileId, i of @tickIndex
            @tickIndex[tileId] = ++i
            if not @tiles[tileId]['volatile']
                continue
            
            if(@tickIndex[tileId] >= @tiles[tileId]['total'])
                @iosocket.sockets.emit 'doneTile', {'tileId': tileId}
                @cleanTile(tileId)
                delete @tickIndex[tileId]

        @getCurrentTimeSlot (error, doc) =>
            if error?
                @logger.error "Could not load current timeslot"
            else
                if (doc? and @currentTimeslot == doc._id) or (not doc? and not @currentTimeslot?)

                    @iosocket.sockets.emit 'tick', @tickIndex #We are still in the same timeslot, we'll send a tick
                    @tickCount++
                    return
                oldTimeslot = @currentTimeslot
                if doc? and @currentTimeslot != doc._id
                    @currentTimeslot = doc._id
                else if @currentTimeslot != null
                    @currentTimeslot = null
                @logger.info "Changing timeslot", {'new': @currentTimeslot, 'old': oldTimeslot}
                @autoCompleteList = undefined
                @setupTiles () =>
        
    setupExpress: () ->
        app = express()
        app.use express.bodyParser()
        dir = __dirname + '/html'
        app.use express.static dir
        app.use expressWinston.logger({
            'transports': @transports
            })
        return app
        
    connectCouchDB: (cb) ->
        nano = nano 'http://localhost:5984'
        nano.db.get @dbName, (err, body) =>
            if err
                @logger.error "No " + @dbName +" database in CouchDB"
                process.exit 1
            else
                @db = nano.use @dbName
                @logger.info "Connected to CouchDB and opened the " + @dbName + " database."
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
            @logger.info "Filter posted", {'filter': req.body, 'timeslot': @currentTimeslot, 'clientIp': req.connection.remoteAddress}
            
            if @availableTiles.length == 0
                res.jsonp {'status': 'error', 'message': 'No empty tiles'}, 500
                @logger.info "No room for filter", {'filter': req.body, 'timeslot': @currentTimeslot}
                return
            
            query = req.body
            tileId = @getTile query
            
            if query.when
                delete query.when
            
            @getOngoingSubmissions (err, data) =>
                if err?
                    res.jsonp {'status': 'error', 'message': err}, 500
                else
                    data = data.submissions
                    @filterSubmissions tileId, query, data, true
                    @logger.info "Filter created", {'filter': req.body, 'results': @tiles[tileId].filter.submissions.map((s) -> s._id), 'timeslot': @currentTimeslot, 'clientIp': req.connection.remoteAddress}
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
            
        #For automated testing purposes, only available if fixedTime is set in config file
        @app.post '/fixedTime', (req, res) =>
            if not @config.fixedTime?
                res.send 'Illegal to set fixedTime when not configured for testing', 500
            else
                time = req.body
                if req.body.length != 5
                    res.send 'Illegal length of time array', 500
                else
                    @config.fixedTime = time
                    res.jsonp {'status': 'ok'}
            
        
##################################
##More specialized queries below##
##################################
        
        #Get the sessions of a day
        @app.get '/day/:id/sessions', (req, res) =>
            @db.get req.params.id, (err, body) =>
                if err?
                    res.send 'Could not load given day', 500
                else
                    if not body.type?
                        res.send 'No day with given id', 404
                        return
                    if body.type != 'day'
                        res.send 'No day with given id', 404
                    else
                        @getSessionsForTimeslots body.timeslots, (err, sessions) =>
                            if err?
                                res.send "Error", 500
                            else
                                res.jsonp sessions
                                
        #Get the submissions of a day
        @app.get '/day/:id/submissions', (req, res) =>
            @db.get req.params.id, (err, body) =>
                if err?
                    res.send 'Could not load given day', 500
                else
                    if not body.type?
                        res.send 'No day with given id', 404
                        return
                    if body.type != 'day'
                        res.send 'No day with given id', 404
                    else
                        @getSubmissionsForTimeslots body.timeslots, (err, submissions) =>
                            if err?
                                res.send "Error", 500
                            else
                                res.jsonp submissions

        #Get the remaining submissions of a day
        @app.get '/day/:id/remainingSubmissions', (req, res) =>
            @db.get req.params.id, (err, body) =>
                if err?
                    res.send 'Could not load given day', 500
                else
                    if not body.type?
                        res.send 'No day with given id', 404
                        return
                    if body.type != 'day'
                        res.send 'No day with given id', 404
                    else
                        @getRemainingSubmissionsForDay body, (err, submissions) =>
                            if err?
                                res.send "Error", 500
                            else
                                res.jsonp submissions
                    
                                
        #Get the keywords of a day
        @app.get '/day/:id/keywords', (req, res) =>
            @db.get req.params.id, (err, body) =>
                if err?
                    res.send 'Could not load given day', 500
                else
                    if not body.type?
                        res.send 'No day with given id', 404
                        return
                    if body.type != 'day'
                        res.send 'No day with given id', 404
                    else
                        @getKeywordsForTimeslots body.timeslots, (err, keywords) =>
                            if err?
                                res.send "Error", 500
                            else
                                res.jsonp keywords
        
        #Get the sessions of a timeslot
        @app.get '/timeslot/:id/sessions', (req, res) =>
            @getSessionsForTimeslots [req.params.id], (err, sessions) =>
                if err?
                    res.send 'Could not load given timeslot', 500
                else
                    res.jsonp sessions
        
        #Get the submissions of a timeslot
        @app.get '/timeslot/:id/submissions', (req, res) =>
            @getSubmissionsForTimeslots [req.params.id], (err, submissions) =>
                if err?
                    res.send 'Could not load given timeslot', 500
                else
                    res.jsonp submissions
                    
        #Get the keywords of a timeslot
        @app.get '/timeslot/:id/keywords', (req, res) =>
            @getKeywordsForTimeslots [req.params.id], (err, keywords) =>
                if err?
                    res.send 'Could not load given timeslot', 500
                else
                    res.jsonp keywords
        
        #Get the submissions that are remaining today
        @app.get '/remainingSubmissionsToday', (req, res) =>
            @getRemainingSubmissionsForToday (err, submissions) =>
                if err?
                    res.send 'Could not get remaining submissions', 500
                else
                    res.jsonp submissions
                    
        @app.get '/keywordMapForRemainingSubmissionsToday', (req, res) =>
            @getRemainingSubmissionsForToday (err, submissions) =>
                if err?
                    res.send 'Could not get remaining submissions', 500
                else
                    res.jsonp (@getKeywordMapForSubmissionList submissions)
        
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
                    
        filterAutocompleteList = (substring, list) ->
            result = _.clone list
            for source, words of list
                filteredWords = _.clone words
                todelete = []
                re = new RegExp substring, 'i'
                keys = Object.keys filteredWords
                for key in keys
                    if key.search(re) == -1
                        todelete.push key
                for key in todelete
                    delete filteredWords[key]
                result[source] = filteredWords
                if Object.keys(filteredWords).length == 0
                    delete result[source]
            return result
        
        
        @app.get '/autocompletelist', (req, res) =>
            newResult = {}
            if @autoCompleteList?
                result = @autoCompleteList
                if req.query.substring? and req.query.substring.length > 0
                    result = filterAutocompleteList req.query.substring, @autoCompleteList
                res.jsonp result 
            else
                @getOngoingSubmissions (err, data) =>
                    if err?
                        res.send 'Could not load ongoing submissions', 500
                    list = []
                    for submission in data.submissions
                        for key in @config.searchFields
                            if submission[key]?
                                if _.isString submission[key]
                                    split = submission[key].split(',')
                                    for word in split
                                        word = word.trim()
                                        if word.length == 0
                                            continue
                                        if not newResult[key]?
                                            newResult[key] = {}
                                        if not newResult[key][word]?
                                            newResult[key][word] = []
                                        if not _.contains newResult[key][word], submission._id
                                            newResult[key][word].push submission._id
                                else if _.isArray submission[key]
                                    for substring in submission[key]
                                        split = substring.split(',')
                                        for word in split
                                            word = word.trim()
                                            if word.length == 0
                                                continue
                                            if not newResult[key]?
                                                newResult[key] = {}
                                            if not newResult[key][word]?
                                                newResult[key][word] = []
                                            if not _.contains newResult[key][word], submission._id
                                                newResult[key][word].push submission._id
                                            
                    @autoCompleteList  = newResult                
                    result = @autoCompleteList
                    if req.query.substring? and req.query.substring.length > 0
                        result = filterAutocompleteList req.query.substring, @autoCompleteList
                    res.jsonp result 
                    

        #Returns a list of all tags of ongoing submissions each tag has a list of submissions matching that tag. 
        #Also a count of all ongoing submissions is returned (which can be used e.g. to size tags in a tag cloud)
        @app.get '/ongoingtags', (req, res) =>
            @getOngoingSubmissions (err, data) ->
                if err?
                    res.send 'Could not load ongoing sessions', 500
                else
                    result = {}
                    result.ongoing = data.ongoing
                    result.timeslot = data.timeslot
                    tags = {}
                    count = 0
                    for submission in data.submissions
                        if submission.tags?
                            for tag in submission.tags
                                count++
                                if tags[tag]?
                                    tags[tag].push submission._id
                                else
                                    tags[tag] = [submission._id]
                    result.tags = tags
                    result.totalItems = count
                    res.jsonp result
                    

        #Returns a list of all keywords of ongoing submissions each keyword has a list of keywords matching that tag. 
        #Also a count of all ongoing submissions is returned (which can be used e.g. to size keywords in a tag cloud)
        @app.get '/ongoingkeywords', (req, res) =>
            @getOngoingSubmissions (err, data) ->
                if err?
                    res.send 'Could not load ongoing sessions', 500
                else
                    result = {}
                    result.ongoing = data.ongoing
                    result.timeslot = data.timeslot
                    keywords = {}
                    count = 0
                    for submission in data.submissions
                        if submission.authorKeywords?
                            for keyword in submission.authorKeywords
                                count++
                                if keywords[keyword]?
                                    keywords[keyword].push submission._id
                                else
                                    keywords[keyword] = [submission._id]
                    result.keywords = keywords
                    result.totalItems = count
                    res.jsonp result
  
        
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
                        
        #Returns the upcoming timeslot (if any)
        @app.get '/upcomingTimeSlot', (req, res) =>
            @getUpcomingTimeSlot (error, doc) =>
                if error?
                    res.send "Could not load current timeslot", 500
                else
                    if not doc?
                        res.send "No ongoing timeslot", 404
                    else
                        res.jsonp doc
                        
        #Returns the current or ongoing timeslot (if any)
        @app.get '/currentOrUpcomingTimeSlot', (req, res) =>
            @getCurrentOrUpcomingTimeSlot (error, doc) =>
                if error?
                    res.send "Could not load current timeslot", 500
                else
                    if not doc?
                        res.send "No ongoing timeslot", 404
                    else
                        res.jsonp doc
                        
        @app.get '/currentAndUpcomingTimeSlot', (req, res) =>
            @getCurrentAndUpcomingTimeSlot (error, doc) =>
                if error?
                    res.send "Could not load current timeslot", 500
                else
                    if not doc?
                        res.send "No ongoing timeslot", 404
                    else
                        res.jsonp doc
                        
        
        
        @app.get '/keywordmap', (req, res) =>
            @db.view 'submission', 'all', (err, body) =>
                if err?
                    res.send 'Could not load submissions', 500
                    return
                    
                submissions = body.rows.map (submission) -> submission.value
                res.jsonp (@getKeywordMapForSubmissionList submissions )

    #Returns a keyword map for a list of submission docs
    getKeywordMapForSubmissionList: (submissionList) ->
        keywordmap = {}
        keywordGroups= {}
        for submission in submissionList
            id = if submission.id? then submission.id else submission._id 
            if not submission.authorKeywords?
                continue
            for keyword in submission.authorKeywords
                if keyword.length == 0
                    continue
                keyword = keyword.replace /["']{1}/gi,""
                keywordSplit = keyword.split ' '
                for k in keywordSplit
                    if k.length == 0
                        continue
                    else
                        if not keywordGroups[k]?
                            keywordGroups[k] = {}
                        if keywordGroups[k][keyword]?
                            keywordGroups[k][keyword]++
                        else
                            keywordGroups[k][keyword] = 1
                if keyword.length <= 1
                    continue
                if keywordmap[keyword]?
                    keywordmap[keyword].push id 
                else
                    keywordmap[keyword] = [id]
        result = {'groups': keywordGroups, 'map': keywordmap}
        return result
    
    ###
    Returns the current time as an array
    Time can be fixed with the fixedTime entry in config
    A time offset can be defined (in miliseconds) with the timeOffset config
    ###
    getTime: () -> #This is just a stub
        if @config.fixedTime?
            date = new Date @config.fixedTime[0], @config.fixedTime[1], @config.fixedTime[2], @config.fixedTime[3], @config.fixedTime[4]
        else
            date = new Date()
        if @config.timeOffset?
            date = new Date(date.getTime() + @config.timeOffset)
        return [date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes()]
    
    createTimeVal: (hour, minute) ->
        hourStr = "" + hour
        minuteStr = "" + minute
        if minuteStr.length == 1
            minuteStr = "0" + minuteStr
        return parseInt(hourStr+minuteStr)
    
    ###
    Gets the remaining days of the conference including the current day
    ###
    getRemainingDays: (cb) ->
        time = @getTime()
        start = time[..2]
        @db.view 'day', 'bydate', {"startkey": start}, (err, days) => #Get all days start from today
            if err?
                cb err, null
            else
                cb null, days.rows
                    
    
    ###
    Returns the currently ongoing timeslot and null of none is ongoing
    ###    
    getCurrentTimeSlot: (cb) ->
        time = @getTime()
        timeVal = @createTimeVal time[3], time[4] #create an int that is easy to compare with
        start = time[..2]
        @getRemainingDays (err, days) =>
            if err?
                cb err, null
            else
                if days.length > 0
                    day = days[0].value
                    @db.fetch {'keys': day.timeslots}, (err, timeslots) =>
                        if err?
                            cb err, null
                        else
                            for timeslot in timeslots.rows
                                tsStart = @createTimeVal timeslot.doc.start[0], timeslot.doc.start[1]
                                tsEnd = @createTimeVal timeslot.doc.end[0], timeslot.doc.end[1]
                                if tsStart <= timeVal && tsEnd >= timeVal
                                    cb null, timeslot.doc
                                    return
                            cb null, null
                else
                    cb null, null
                    
    ###
    Returns the upcoming timeslot
    ###
    getUpcomingTimeSlot: (cb) ->
        @getRemainingDays (err, days) =>
            if err?
                cb err, null
            else
                if days.length == 0
                    cb null, null
                    return
                day = days[0].value
                time = @getTime()
                timeVal = @createTimeVal time[3], time[4] #create an int that is easy to compare with
                start = time[..2]
                @db.view 'day', 'bydate', {"startkey": start}, (err, days) => #Get all days start from today
                    if err?
                        cb err, null
                    else
                        @db.fetch {'keys': day.timeslots}, (err, timeslots) =>
                            if err?
                                cb err, null
                            else
                                lowestStart = 9999
                                for timeslot in timeslots.rows
                                    tsStart = @createTimeVal timeslot.doc.start[0], timeslot.doc.start[1]
                                    if tsStart > timeVal
                                        if not found? or tsStart < lowestStart
                                            found = timeslot
                                            lowestStart = tsStart
                                if found?
                                    cb null, found.doc
                                else
                                    if days.rows.length > 1 #We didn't find an upcoming timeslot this day, lets try to look at tomorrow
                                        day = days.rows[1].value
                                        @db.fetch {'keys': day.timeslots}, (err, timeslots2) =>
                                            if err?
                                                cb err, null
                                                return
                                            else
                                                lowestStart = 9999
                                                found = null
                                                for timeslot in timeslots2.rows
                                                    tsStart = @createTimeVal timeslot.doc.start[0], timeslot.doc.start[1]
                                                    if tsStart < lowestStart
                                                        lowestStart = tsStart
                                                        found = timeslot
                                                if found?
                                                    cb null, found.doc
                                                else
                                                    cb null, null
                                    else
                                        cb null, null
                    
    ### 
    Used to get the current or upcoming timeslot. Will also handle day changes.
    It is possible to provide an additional boolean getUpcoming to only return data if there is an ongoing timeslot.
    ###
    getCurrentOrUpcomingTimeSlot: (cb, getUpcoming = true) ->
        @getCurrentTimeSlot (err, timeslot) =>
            if not timeslot? and not getUpcoming
                cb null, null
            else if not timeslot?
                @getUpcomingTimeSlot (err, timeslot) =>
                    cb err, timeslot
            else
                cb err, timeslot
                
    getCurrentAndUpcomingTimeSlot: (cb) ->
        result = {}
        @getCurrentTimeSlot (err, ongoingTimeslot) =>
            if err?
                cb err, null
                return
            else
                result.ongoing = ongoingTimeslot
                @getUpcomingTimeSlot (err, upcomingTimeslot) =>
                    if err?
                        cb err, null
                        return
                    else
                        result.upcoming = upcomingTimeslot
                        cb null, result
    
    getRemainingSubmissionsForToday: (cb) ->
        @getRemainingDays (err, days) =>
            if err?
                cb err, null
            if days.length > 0
                @getRemainingSubmissionsForDay days[0].value, (err, submissions) =>
                    cb err, submissions
            else
                cb [], null
    
    getRemainingSubmissionsForDay: (day, cb) ->
        @getRemainingTimeslotsForDay day, (err, timeslots) =>
            if err?
                cb err, null
            else
                ids = timeslots.map (timeslot) -> timeslot.id
                time = @getTime()
                timeVal = @createTimeVal time[3], time[4]
                remainingSubmissions = []
                @getSubmissionsForTimeslots ids, (err, submissions) =>
                    if err?
                        cb err, null
                        return
                    else
                        for submission in submissions
                            submissionStart = @createTimeVal submission.startTime[3], submission.startTime[4]
                            date = new Date submission.startTime[0], submission.startTime[1], submission.startTime[2], submission.startTime[3], submission.startTime[4]
                            endDate = new Date date.getTime() + 60000*submission.duration
                            submissionEnd = @createTimeVal endDate.getHours(), endDate.getMinutes()
                            if submissionStart > timeVal || submissionEnd > timeVal
                                remainingSubmissions.push submission
                    cb null, remainingSubmissions
    
                        
    getRemainingTimeslotsForDay: (day, cb) ->
        @db.fetch {"keys": day.timeslots}, (err, timeslots) =>
            if err?
                cb err, null
                return
            time = @getTime()
            currentDate = time[0..2]
            currentTime = @createTimeVal time[3], time[4]
            if currentDate > day.date
                cb null, []
            else if currentDate < day.date
                cb null, timeslots.rows
            else
                remainingTimeslots = []
                for timeslotRow in timeslots.rows
                    timeslot = timeslotRow.doc
                    timeslotStart = @createTimeVal timeslot.start[0], timeslot.start[1]
                    timeslotEnd = @createTimeVal timeslot.end[0], timeslot.end[1]
                    if timeslotStart > currentTime || timeslotStart > currentTime
                        remainingTimeslots.push timeslotRow
                cb null, remainingTimeslots

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
    
    getTimeslots: (timeslotIds, cb) ->
        @db.fetch {'keys': timeslotIds}, (err, body) =>
            if err?
                cb err, null
            else
                cb null, body
    
    getSessionsForTimeslots: (timeslotIds, cb) ->
        @getTimeslots timeslotIds, (err, timeslots) =>
            if err?
                cb err, null
            else
                sessionIds = []
                for timeslot in timeslots.rows
                    for sessionId in timeslot.doc.sessions
                        sessionIds.push sessionId
                
                @db.fetch {'keys': sessionIds }, (err, body) =>
                    if err?
                        cb err, null
                    else
                        sessions = body.rows.map (row) -> row.doc
                        @inlineSubmissionsForSessions sessions, 0, () =>
                            cb null, sessions
    
    getSubmissionsForTimeslots: (timeslotIds, cb) ->
        @getSessionsForTimeslots timeslotIds, (err, sessions) =>
            if err?
                cb err, null
            else
                submissions = []
                for session in sessions
                    for submission in session.submissions
                        submissions.push submission
                cb null, submissions
    
    getKeywordsForTimeslots: (timeslotIds, cb) ->
        @getSubmissionsForTimeslots timeslotIds, (err, submissions) =>
            if err?
                cb err, null
            else
                cb null, @getKeywordMapForSubmissionList(submissions)
    
    getOngoingSessions: (cb) ->
        result = {}
        @getCurrentAndUpcomingTimeSlot (error, doc) =>
            if error?
                cb error, null
            else
                if not doc? or (not doc.ongoing? and not doc.upcoming?)
                    cb new Error "No data for given time", null
                else
                    if doc.ongoing?
                        result.ongoing = true
                        result.timeslot = doc.ongoing
                    else
                        result.ongoing = false
                        result.timeslot = doc.upcoming
                    @db.fetch {'keys': result.timeslot.sessions}, (err, body) =>
                        if err?
                            cb err, null
                        else
                            @db.view 'session', 'always', (err, alwaysOngoing) =>
                                alwaysOngoing.rows.map (row) -> 
                                    row.doc = row.value
                                    delete row.value
                                rows = body.rows.concat alwaysOngoing.rows
                                
                                sessions = rows.map (row) -> row.doc
                                @inlineSubmissionsForSessions sessions, 0, () =>
                                    result.sessions = sessions
                                    cb null, result
                
    getOngoingSubmissions: (cb) ->
        result = {}
        @getOngoingSessions (err, sessions) =>
            if err?
                cb err, null
            else
                result.ongoing = sessions.ongoing
                result.timeslot = sessions.timeslot
                submissions = []
                for session in sessions.sessions
                    for submission in session.submissions
                        submissions.push submission
                result.submissions = submissions
                cb null, result

    filterSubmissions: (tileId, query, submissions, volatile = false) ->
        matches = []
        if query.all?
            toQuery = @config.searchFields
            for subquery in toQuery
                filter = {}
                filter[subquery] = query.all
                submatches = s.matchArray submissions, filter
                matches = _.union matches, submatches
        else
            matches = s.matchArray submissions, query
        matches.sort (s1, s2) -> #Sort by room and order by startTime
            room1 = if s1.room? then s1.room else ''
            room2 = if s2.room? then s2.room else ''
            if room1 != room2
                if room1 < room2
                    return -1
                else
                    return 1
            else
                if s1.startTime? and not s2.startTime?
                    return -1
                else if not s1.startTime? and s2.startTime?
                    return 1
                else if not s1.startTime? and not s2.startTime?
                    return 0
                else if s1.startTime < s2.startTime
                    return -1
                else
                    return 1
            return 0
        filter = {'query': query, 'submissions': matches, 'tileId': tileId}
        @tiles[tileId]['filter'] = filter
        @tiles[tileId]['timestamp'] = new Date()
        @tiles[tileId]['total'] = matches.length
        @tiles[tileId]['volatile'] = volatile
        @tickIndex[tileId] = -1

server = new GlanceServer()