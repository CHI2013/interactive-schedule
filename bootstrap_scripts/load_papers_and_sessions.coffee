csv = require 'ya-csv'
nano = require('nano')('http://127.0.0.1:5984')
videos = require('./videos')

chidb = nano.db.use('chi2013');

submissionsToSessions = {}

tags = "theory,crowdsourcing,infovis,multi-surface,visualization,design,health,business,global,systems,toolkits,cscw,ubiquitous computing,tabletops,sense-making,augmented reality,performance,elderly,multicultural,participatory design,BCI,music,accessibility,science,gender HCI,prototyping,fitts' law,hypertext,www".split ','

randomNumbers = () ->
    r1 = Math.floor Math.random()*tags.length
    r2 = Math.floor Math.random()*tags.length
    r3 = Math.floor Math.random()*tags.length
    if r1 != r2 and r1 != r3 and r2 != r3
        return [r1, r2, r3]
    else
        return randomNumbers()

giveMeTags = () ->
    tagnos = randomNumbers()
    return [tags[tagnos[0]], tags[tagnos[1]], tags[tagnos[2]]]

session_reader = csv.createCsvFileReader process.argv[3], {
    'columnsFromHeader': true,
    'separator': ',',
    'quote': '"',
    'escape': '"',       
    'comment': '',
}

days = {
        'day_1': {
                'type': 'day',
                'number': 1,
                'name': 'Saturday',
                'timeslots': ['timeslot_1', 'timeslot_2', 'timeslot_3', 'timeslot_4'],
                'date': [2012, 5, 5]
            },
        'day_2': {
                'type': 'day',
                'number': 2,
                'name': 'Sunday',
                'timeslots': ['timeslot_5', 'timeslot_6', 'timeslot_7', 'timeslot_8'],
                'date': [2012, 5, 6]
            },
        'day_3': {
                'type': 'day',
                'number': 3,
                'name': 'Monday',
                'timeslots': ['timeslot_9', 'timeslot_10', 'timeslot_11', 'timeslot_12'],
                'date': [2012, 5, 7]
            },
        'day_4': {
                'type': 'day',
                'number': 4,
                'name': 'Tuesday',
                'timeslots': ['timeslot_13', 'timeslot_14', 'timeslot_15', 'timeslot_16'],
                'date': [2012, 5, 8]
            },
        'day_5': {
                'type': 'day',
                'number': 5,
                'name': 'Wednesday',
                'timeslots': ['timeslot_17', 'timeslot_18', 'timeslot_19', 'timeslot_20'],
                'date': [2012, 5, 9]
            },
        'day_6': {
                'type': 'day',
                'number': 6,
                'name': 'Thursday',
                'timeslots': ['timeslot_21', 'timeslot_22', 'timeslot_23', 'timeslot_24'],
                'date': [2012, 5, 10]
            }
    }

timeslots = {}

for id, day of days
    timeslots[day.timeslots[0]] = {
        'type': 'timeslot',
        'number': 1,
        'name': 'Morning',
        'sessions': [],
        'start': [9, 30],            
        'end': [10, 50]
    }
    timeslots[day.timeslots[1]] = {
        'type': 'timeslot',
        'number': 2,
        'name': 'Before Lunch',
        'sessions': [],
        'start': [11, 30],
        'end': [12, 50]
    }
    timeslots[day.timeslots[2]] = {
        'type': 'timeslot',
        'number': 3,
        'name': 'After Lunch',
        'sessions': [],
        'start': [14, 30],
        'end': [15, 50]
    }
    timeslots[day.timeslots[3]] = {
        'type': 'timeslot',
        'number': 4,
        'name': 'Afternoon',
        'sessions': [],
        'start': [16, 30],
        'end': [17, 50]
    }

session_reader.addListener 'data', (data) ->
    date = new Date(data.Date + ' ' + data.Time)
    startTime = [date.getFullYear(), date.getMonth()+1, date.getDate(), date.getHours(), date.getMinutes()]
    data.startTime = startTime
    
    for id, day of days
        if day.date[2] == startTime[2]
            for timeslot in day.timeslots
                if timeslots[timeslot].start[0] == startTime[3]
                    timeslots[timeslot].sessions.push 'session_'+data['ID']
    
    data.type = 'session'
    if data['Submission IDs'] && data['Submission IDs'] != '"'
        data['Submission IDs'] = data['Submission IDs'].split ' '
    else
        data['Submission IDs'] = []
    for submission in data['Submission IDs']
        submissionsToSessions[submission] = data['ID']
    chidb.insert data, 'session_'+data['ID'], (err, body) ->
        if err?
            console.log err
        else
            
    
session_reader.addListener 'end', () ->
    paper_reader = csv.createCsvFileReader process.argv[2], {
        'columnsFromHeader': true,
        'separator': ',',
        'quote': '"',
        'escape': '"',       
        'comment': '',
    }
    
    paper_reader.addListener 'data', (data) ->
        submission = {}
        submission.id = data.ID
        if !submission.id
            return
        submission.type = 'submission'
        submission.title = data.Title
        if data['Author list']?
            submission.authors = data['Author list'].split(',').map (name) ->
                name.trim()
        
        if videos.videos[submission.id]?
            submission.video = videos.videos[submission.id]
        else if videos.videos[submission.id[0..4] + "0" + submission.id[5..]]?
            submission.video = videos.videos[submission.id[0..4] + "0" + submission.id[5..]]

        if data['Keywords']?
            keywords = data['Keywords'].split(/[\n\t,;\\]+/).map (word) ->
                word.trim().toLowerCase().replace '.', ''
            submission.keywords = []
            for keyword in keywords
                if keyword.length != 0
                    submission.keywords.push keyword
            
        submission.contributionType = data['Paper or Note']
        submission.session = submissionsToSessions[submission.id]
        submission.tags = giveMeTags()
        chidb.insert submission, 'submission_'+submission.id, (err, body) ->
            if err?
                console.log err
    
    paper_reader.addListener 'end', () ->
        for timeslotId, timeslot of timeslots
            chidb.insert timeslot, timeslotId, (err, body) ->
                if err?
                    console.log err
        for dayId, day of days
            chidb.insert day, dayId, (err, body) ->
                if err?
                    console.log err
            
    