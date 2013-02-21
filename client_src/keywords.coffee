root = exports ? window

$(document).mousemove (e) ->
   root.mouseX = e.pageX 
   root.mouseY = e.pageY

#$(".classForHoverEffect").mouseover(function(){
#  $('#DivToShow').css({'top':mouseY,'left':mouseX}).fadeIn('slow');
#});

$(document).ready () ->
    $('body').mousedown () ->
        $('.hover').hide()
        if root.selected?
            root.selected.removeClass 'highlight'
    $.get '../keywordmap', (data) ->
        console.log data
        
        totalKeywords = 0
        totalUniqueKeywords = 0
        keywordsUsedMoreThanOnce = 0
        keywordsUsedOnce = 0
        max = 0
        for keyword, submissions of data.map
            totalUniqueKeywords++
            totalKeywords  += submissions.length
            if submissions.length > max
                max = submissions.length
        
        keywords = []
        for keyword, submission of data.map
            if submission.length > 1
                keywordsUsedMoreThanOnce++
            else
                keywordsUsedOnce++
            keywords.push {'keyword': keyword, 'length': submission.length}
        keywords = _.sortBy keywords, (keyword) ->
            return -keyword.length
        
        maxGroups = 0
        for group, content of data.groups
            for item, count of content
                maxGroups += count
        
        $('#stats').append "<h2>Stats:<h2/>"
        $('#stats').append "Total unique keywords: " + totalUniqueKeywords
        $('#stats').append "<br/>"
        $('#stats').append "Total keywords used: " + totalKeywords
        $('#stats').append "<br/>"
        $('#stats').append "Keywords used more than once: " + keywordsUsedMoreThanOnce
        $('#stats').append "<br/>"
        $('#stats').append "Keywords used once: " + keywordsUsedOnce 
        
        $('#stats').append "<h2>Keywords grouped by words:<h2/>"
        
        keywordGroupsDiv = $('.kwtagcloud')
        keywordP = $ '<p/>'
        keywordGroupsDiv.append keywordP
        
        usedKeywords = []
        
        sortedGroups = []
        for group, content of data.groups
            sortedGroups.push {'group': group, 'content': content}
        sortedGroups = _.sortBy sortedGroups, (group) ->
            return group.group
        for groupPair in sortedGroups
            group = groupPair.group
            content = groupPair.content
            length = 0
            last = null
            for item, count of content
                length += count
                last = item
            if length == 1 and _.contains usedKeywords, last 
                continue
            for item, count of content
                if not _.contains usedKeywords, item
                    usedKeywords.push item
            span= $('<span class="kw"/>')
            size = 80 + (length / (maxGroups * 1.0)) * maxGroups * 4
            console.log size
            span.css 'font-size', Math.ceil(size) + '%'
            span.append group
            span.mouseover () ->
                if root.selected?
                    root.selected.removeClass 'highlight'
                root.selected = $(this)
                $('.hover').css({'top': $(this).offset().top + $(this).outerHeight(),'left': $(this).offset().left}).show()
                $('.hover').empty()
                keywords = data.groups[$(this).text()]
                total = 0
                keywordCount = 0
                $('.hover').append $('<h3>' + $(this).text() + '<h3>')
                totalKeywordP = $('<p class="totalKeywords">Total keywords in group: </p>')
                totalPaperP = $('<p class="totalPapers">Total occurences in group: </p>')
                $('.hover').append totalKeywordP  
                $('.hover').append totalPaperP   
                $('.hover').append $('<br/>') 
                sortedKeywords = []
                for keyword, count of keywords
                    sortedKeywords.push {'keyword': keyword, 'count': count}
                sortedKeywords = _.sortBy sortedKeywords, (pair) ->
                    return -pair.count
                for pair in sortedKeywords
                    keyword = pair.keyword
                    count = pair.count
                    keywordCount++
                    total += count
                    keywordSpan = $('<span class="kw2"/>')
                    keywordSpan.append keyword + ": " + count
                    $('.hover').append keywordSpan
                    $('.hover').append $('<br/>')
                totalPaperP.append total
                totalKeywordP.append keywordCount
                $(this).addClass 'highlight'
            keywordP.append span
            keywordP.append " "