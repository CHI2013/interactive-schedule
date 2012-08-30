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
    console.log data.ID
    console.log data.Title
    console.log data['Author list']
    console.log data['Paper or Note']
    console.log data['Keywords']
    console.log data['Awards']