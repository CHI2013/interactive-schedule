csv = require 'ya-csv'

authorRegExps = {
    'firstName': /^Author given first name [\d]+/,
    'middleName': /^Middle initial or name [\d]+/,
    'lastName': /^Author last\/family name [\d]+/,
    'email': /^Valid email address [\d]+/,
    'department1': /^Primary Affiliation [\d]+ - Department\/School\/Lab/,
    'institution1': /^Primary Affiliation [\d]+ - Institution/,
    'city1': /^Primary Affiliation [\d]+ - City/,
    'stateProvince1': /^Primary Affiliation [\d]+ - State or Province/,
    'country1': /^Primary Affiliation [\d]+ - Country/,
    'department2': /^Secondary Affiliation (optional) [\d]+ - Department\/School\/Lab/,
    'institution2': /^Secondary Affiliation (optional) [\d]+ - Institution/,
    'city2': /^Secondary Affiliation (optional) [\d]+ - City/,
    'stateProvince2': /^Secondary Affiliation (optional) [\d]+ - State or Province/,
    'country2': /^Secondary Affiliation (optional) [\d]+ - Country/
    }
    
    
attributeMap = {
    'ID': 'submissionId',
    'ID 1': 'submissionId2',
    'Title': 'title',
    'Abstract': 'abstract',
    'Page Length': 'pageLength',
    'Paper or Note': 'type',
    'Primary and Additional ACM Classifiers': 'acmClassifiers',
    'Thumbnail Image Caption': 'thumbnailCaption',
    'Contribution & Benefit Statement (Mandatory Field)': 'contributionAndBenefit',
    'Presenting Author': 'presentingAuthor',
    'Backup Presenting Author': 'backupPresentingAuthor'
}

paper_reader = csv.createCsvFileReader process.argv[2], {
    'columnsFromHeader': true,
    'separator': ',',
    'quote': '"',
    'escape': '"',       
    'comment': '',
}

i = 0

getNumberedKey = (obj, key, regexp) ->
    numberRegExp = /[\d]+/g
    nameMatch = key.match regexp
    result = null
    if nameMatch != null
        numberMatch = key.match numberRegExp
        return [numberMatch[0]-1, obj[key]]
        

addAuthors = (submission, data) ->
    authors = []
    for key in Object.keys data
        if data[key] == '"'
            continue
        for info, regexp of authorRegExps
            pair = getNumberedKey data, key, regexp
            if pair?
                if not authors[pair[0]]?
                    authors[pair[0]] = {}
                authors[pair[0]][info] = data[key]
    submission.authors = authors

addContact = (submission, data) ->
    contact = {}
    contact.firstName = data['Contact given name']
    contact.lastName = data['Contact family name']
    contact.email = data['Contact Email']
    submission.contact = contact
    
addKeywords = (submission, data) ->
    submission.keywords = {}
    if data['Author Keywords']?
        keywords = data['Author Keywords'].split(/[\n\t,;\\]+/).map (word) ->
            word.trim().toLowerCase().replace '.', ''
        submission.keywords = []
        for keyword in keywords
            if keyword.length != 0
                submission.keywords.push keyword

addAttribute = (submission, data, keyInData, targetKey) ->
    if not data[keyInData]?
        return
    if data[keyInData] == '"'
        return
    submission[targetKey] = data[keyInData]
    
addCommunities = (submission, data) ->
    submission.chiCommunities = if data["CHI Communities"]? then data["CHI Communities"].split ','

paper_reader.addListener 'data', (data) ->
    console.log "======================================================================================="
    submission = {}
    
    for keyInData, targetKey of attributeMap
        addAttribute submission, data, keyInData, targetKey
    
    addCommunities submission, data
    addAuthors submission, data
    addKeywords submission, data
    addContact submission, data

    console.log submission