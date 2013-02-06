nano = require('nano')('http://127.0.0.1:5984')
sets = require 'simplesets'

chidb = nano.db.use('chi2013');

submissionData = require('./' + process.argv[2]).rows
sessionData = require('./' + process.argv[3]).rows
schedule = require('./' + process.argv[4]).rows
#console.log submissions
#console.log sessions
#console.log schedule

days = {
        'day_1': {
                'type': 'day',
                'number': 1,
                'name': 'Saturday',
                'timeslots': ['timeslot_1', 'timeslot_2', 'timeslot_3', 'timeslot_4'],
                'date': [2013, 4, 27]
            },
        'day_2': {
                'type': 'day',
                'number': 2,
                'name': 'Sunday',
                'timeslots': ['timeslot_5', 'timeslot_6', 'timeslot_7', 'timeslot_8'],
                'date': [2013, 4, 28]
            },
        'day_3': {
                'type': 'day',
                'number': 3,
                'name': 'Monday',
                'timeslots': ['timeslot_9', 'timeslot_10', 'timeslot_11', 'timeslot_12'],
                'date': [2013, 4, 29]
            },
        'day_4': {
                'type': 'day',
                'number': 4,
                'name': 'Tuesday',
                'timeslots': ['timeslot_13', 'timeslot_14', 'timeslot_15', 'timeslot_16'],
                'date': [2013, 4, 30]
            },
        'day_5': {
                'type': 'day',
                'number': 5,
                'name': 'Wednesday',
                'timeslots': ['timeslot_17', 'timeslot_18', 'timeslot_19', 'timeslot_20'],
                'date': [2013, 1, 5]
            },
        'day_6': {
                'type': 'day',
                'number': 6,
                'name': 'Thursday',
                'timeslots': ['timeslot_21', 'timeslot_22', 'timeslot_23', 'timeslot_24'],
                'date': [2013, 2, 5]
            }
    }

timeslots = {}

for id, day of days
    timeslots[day.timeslots[0]] = {
        'type': 'timeslot',
        'number': 1,
        'name': 'Morning',
        'sessions': [],
        'start': [9, 0],            
        'end': [10, 20]
    }
    timeslots[day.timeslots[1]] = {
        'type': 'timeslot',
        'number': 2,
        'name': 'Before Lunch',
        'sessions': [],
        'start': [11, 0],
        'end': [12, 20]
    }
    timeslots[day.timeslots[2]] = {
        'type': 'timeslot',
        'number': 3,
        'name': 'After Lunch',
        'sessions': [],
        'start': [14, 0],
        'end': [15, 20]
    }
    timeslots[day.timeslots[3]] = {
        'type': 'timeslot',
        'number': 4,
        'name': 'Afternoon',
        'sessions': [],
        'start': [16, 0],
        'end': [17, 20]
    }

sessions = {}

for session in sessionData 
    sessionDoc = {}
    sessions[session.value._id] = sessionDoc
    sessionDoc.type = 'session'
    sessionDoc.venue = session.value.venue
    sessionDoc.title = session.value.title
    sessionDoc.tags = session.value.tags
    sessionDoc.communities = session.value.tags
    sessionDoc.personas = session.value.personas
    sessionDoc.tags = session.value.tags
    sessionDoc.communities = session.value.communities
    sessionDoc.submissions = session.value.content
    for sch in schedule
        if session.value.schedule == sch.id
            sessionDoc.room = sch.value.room
            sessionDoc.venue = sch.value.venue
    
    day = session.value.timeslot.split(' ')[0]
    start = session.value.timeslot.split(' ')[1].split('-')[0].split(':').map (val) -> parseInt val #Whoa!
    for id, dayValue of days
        if dayValue.name == day
            for timeslot in dayValue.timeslots
                if timeslots[timeslot].start[0] == start[0]
                    sessionDoc.timeslot = timeslot
                    timeslots[timeslot].sessions.push session.value._id

submissions = {}

for submission in submissionData
    submissionValue = submission.value
    delete submissionValue._id
    delete submissionValue._rev
    submissions[submission.id] = submissionValue

insertInDb = (dict) ->
    for id, value of dict
       chidb.insert value, id, (err, body) ->
           if err?
               console.log err 

insertInDb days
insertInDb timeslots
insertInDb sessions            
insertInDb submissions