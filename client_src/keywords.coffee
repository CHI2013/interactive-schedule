root = exports ? window

$(document).ready () ->
    $.get '../keywordmap', (data) ->
        totalKeywords = 0
        totalUniqueKeywords = 0
        keywordsUsedMoreThanOnce = 0
        keywordsUsedOnce = 0
        max = 0
        for keyword, submissions of data
            totalUniqueKeywords++
            totalKeywords  += submissions.length
            if submissions.length > max
                max = submissions.length
        keywords = []
        for keyword, submission of data
            if submission.length > 1
                keywordsUsedMoreThanOnce++
            else
                keywordsUsedOnce++
            keywords.push {'keyword': keyword, 'length': submission.length}
        keywords = _.sortBy keywords, (keyword) ->
            return -keyword.length 
        $('body').append "<h2>Stats:<h2/>"
        $('body').append "Total unique keywords: " + totalUniqueKeywords
        $('body').append "<br/>"
        $('body').append "Total keywords used: " + totalKeywords
        $('body').append "<br/>"
        $('body').append "Keywords used more than once: " + keywordsUsedMoreThanOnce
        $('body').append "<br/>"
        $('body').append "Keywords used once: " + keywordsUsedOnce 
        $('body').append "<h2>Keywords sorted by usage:<h2/>"
        for keyword in keywords
            div = $('<div/>')
            size = 100 + (keyword.length / (max * 1.0)) * 200 
            div.css 'font-size', Math.ceil(size) + '%'
            div.append keyword.keyword + ": " + keyword.length
            $('body').append div