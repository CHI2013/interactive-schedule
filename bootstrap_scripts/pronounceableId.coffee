words = require './illegalWords.js'

choose = (choices) ->
  index = Math.floor Math.random() * choices.length
  return choices[index]

getFriendlyID = (length) ->
    v = 'aeiou'
    c = 'bdfghklmnprstvw'
    result = ""
    for i in [0..length-1]
        choice = null
        if i%2
            choice = choose v
        else
            choice = choose c
        result += choice
    return result

getUniqueFriendlyID = (usedIds, length) ->
    LIMIT = 1000

    count = 0
    while count < LIMIT
        id = getFriendlyID length
        if id not in usedIds and id not in words.illegal
            break
        count += 1
        id = ''
    return id


exports.getListOfPronounceableIds = (length, count) ->
    if count > 1000
        console.log "Cannot generate more than 1000 words"
        return []
    usedIds = []
    for i in [0..count-1]
        id = getUniqueFriendlyID usedIds, length
        if not id?
            break
        usedIds.push id
    return usedIds