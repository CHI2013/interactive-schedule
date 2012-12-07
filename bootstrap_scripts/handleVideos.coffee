nano = require('nano')('http://127.0.0.1:5984')
http = require 'http'

chidb = nano.db.use 'chi2013'

papersWithVideos = []
#papersToUse = {'notes': [], 'papers': []}

papersToUse = { notes: [ 'paper1210', 'paper120', 'paper1562', 'paper1067', 'paper231', 'paper521', 'paper1075', 'paper1563'], papers: ['paper1224', 'paper1063', 'paper150', 'paper622', 'paper251', 'paper1158', 'paper1119', 'paper464', 'paper1837' ] }

#chidb.get 'timeslot_19', (err, body) ->
#    chidb.fetch {'keys': body.sessions}, (err, body) ->
#        for session in body.rows
#            for paper in session.doc['Submission IDs']
#                papersWithVideos.push paper
#        papersWithVideos = papersWithVideos.map (x) -> 'submission_' +  x
#        chidb.fetch {'keys': papersWithVideos}, (err, body) ->
#            for paper in body.rows
#                if paper.doc.contributionType == 'Paper'
#                    papersToUse.papers.push paper.id
#                else
#                    papersToUse.notes.push paper.id
#                console.log papersToUse
options = {
    host: 'localhost',
    port: 8000,
    path: '/ongoingsessions',
    method: 'GET'
  }

toReplace = {}

toUpdate = {}

insert = (session, submissions) ->
    chidb.get session, (err, body) ->
        body['Submission IDs'] = submissions
        chidb.insert body, body._id, (err, body) ->
            if err?
                console.log err

req = http.get options, (res) ->
    res.setEncoding 'utf8'
    res.on 'data', (chunk) ->
        for session in JSON.parse chunk
            for submission in session.submissions
                if submission.video == 'NoVideo.mp4'
                    if submission.contributionType == 'Note'
                        paperToUse = papersToUse.notes.pop()
                    else
                        paperToUse = papersToUse.papers.pop()
                    newSubmissionIds = [paperToUse]
                    for suid in session['Submission IDs']
                        if suid != submission.id
                            newSubmissionIds.push suid
                    toUpdate[session._id] = newSubmissionIds
        for session, submissions of toUpdate
            insert session, submissions