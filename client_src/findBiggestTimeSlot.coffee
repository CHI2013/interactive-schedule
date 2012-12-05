root = exports ? window

$(document).ready () ->
    sessions = {}
    timeslots = {}
    $.get '../session', (data) ->
        for session in data
            sessions[session.id] = session.value['Submission IDs'].length
        $.get '../timeslot', (data) ->
            for timeslot in data
                timeslots[timeslot.id] = 0
                for session in timeslot.value.sessions
                    timeslots[timeslot.id] += sessions[session]
            totals = []
            for id, count of timeslots
                if count > 0
                    totals.push count
            console.log (totals.reduce (x, y) -> x + y) / totals.length