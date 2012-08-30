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

tags = "theory,crowdsourcing,infovis,multi-surface,visualization,design, health,business,global,systems,toolkits,cscw,ubiquitous computing,tabletops,sense-making,augmented reality,performance,elderly,multicultural,participatory design,BCI,music,accessibility,science,gender HCI,prototyping,fitts' law,hypertext,www".split ','

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

reader.addListener 'data', (data) ->
    date = new Date(data.Date + ' ' + data.Time)
    startTime = [date.getFullYear(), date.getMonth()+1, date.getDate(), date.getHours(), date.getMinutes()]
    data.startTime = startTime
    
    data.type = 'session'
    data['Submission IDs'] = data['Submission IDs'].split ' '
    data.tags = giveMeTags()
    
    chidb.insert data, 'session_'+data['ID'], (err, body) ->
        if err?
            console.log err