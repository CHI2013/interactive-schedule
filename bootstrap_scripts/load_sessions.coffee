csv = require 'ya-csv'
nano = require('nano')('http://127.0.0.1:5984')

chidb = nano.db.use('chi2013');

reader = csv.createCsvFileReader process.argv[2], {
    'columnsFromHeader': true,
    'separator': ',',
    'quote': '"',
    'escape': '"',       
    'comment': '',
}

reader.addListener 'data', (data) ->
    date = new Date(data.Date + ' ' + data.Time)
    startTime = [date.getFullYear(), date.getMonth()+1, date.getDate(), date.getHours(), date.getMinutes()]
    data.startTime = startTime
    
    data.type = 'session'
    data['Submission IDs'] = data['Submission IDs'].split ' '
    
    chidb.insert data, 'session_'+data['ID'], (err, body) ->
        if err?
            console.log err