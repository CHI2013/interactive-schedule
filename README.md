glance
======

Description
-----------

glance is the back-end for the new CHI2013 papers-at-a-glance system.

Installing and running
----------------------

You'll need [node.js](http://nodejs.org), [CoffeeScript](http://coffeescript.org) and [CouchDB](http://couchdb.apache.org) to run the server.
You will also need the CHI2013 program data. The CHI2013 program data should be extracted into bootstrap_scripts/json

Run 'npm install' in the root of glance
Now go to the folder 'bootstrap_scripts' and run 

    sh bootstrap.sh
    
To compile the (now very simple client code) in the root of glace run 'cake build'

Change the config.json to point at the right database in CouchDB

NOW you can run the server by from the glance root:

    coffee glance.coffee config.json

The server will now run on http://localhost:8000

If you just browse there nothing will happen but http://localhost:8000/session should dump all sessions.

You can see a bit of interaction if you browser to http://localhost:8000/phone.html and look at the javascript console output. (The functionality of mobile.html is implemented in phone.coffee).
If you post a new filter

    curl -X POST http://localhost:8000/filters -H "Content-Type: application/json" -d '{"authorKeywords": ["visualization", "infoviz"]}'
    
Usage
------


The glance server provides a basic REST based API.

###Central concepts and API

 * __Tiles__
    + represents the tiles on the large display.
    + can have type:
      * map: the overview map of the conference
      * filter: displaying contributions that match a given filter
      * feed: a twitter feed
      * message: a message from the organisers
    + REST api
      * GET on _http://server.url:8000/tiles_: returns all tiles
      * GET on _http://server.url:8000/tiles/[tileID]_: returns a specific tile
 * __Sessions__
   + represents the sessions of the conference
   + has references to all the contributions associated to the session
   + REST api
     * GET on _http://server.url:8000/session_: returns all sessions
     * GET on _http://server.url:8000/session/[sessionID]_: returns a specific session
     * GET on _http://server.url:8000/ongoingsessions_: returns all sessions that are currently ongoing, or if nothing is ongoing the upcoming
 * __Submissions__
   + represents the submissions to the conference
   + REST api
     * GET on _http://server.url:8000/submission_: returns all submissions
     * GET on _http://server.url:8000/submission/[submissionID]_: returns a specific submission
     * GET on _http://server.url:8000/submission/[submissionID]/video_: redirects to the optional video material of a submission
     * GET on _http://server.url:8000/ongoingsubmissions_: returns all submissions that are currently ongoing, or if nothing is ongoing the upcoming
 * __Timeslots__
   + represents a timeslot in a day
   + each timeslot contains a set of sessions
   + REST api
     * GET on _http://server.url:8000/timeslot_: returns all timeslots
     * GET on _http://server.url:8000/timeslot/[timeslotID]_: returns a specific timeslot
     * GET on _http://server.url:8000/currenttimeslot_: returns the current ongoing or upcoming timeslot
 * __Days__
   + Represents the days of the conference
   + Each day contains 4 timeslots (morning, before lunch, after lunch, afternoon)
   + REST api
     * GET on _http://server.url:8000/day_: returns all days
     * GET on _http://server.url:8000/day/[dayID]_: returns a specific day
 * __Filters__
   + Filters are applied by posting a query to the server. The server will associate an available tile with the given filter.
   + When posting a query to the server the filter is stored in the data structure of its associated tile including the query, the submissions that match the query and a timestamp.
   + REST api
      * POST on _http://server.url:8000/filters_: The body should be a json structure in the [jsql query language](https://github.com/deitch/searchjs). The query is applied to submissions. 
         + Example query: {"tags": ["visualization", "infoviz"]} will create a filter with all submissions from currently ongoing sessions that match either the tag "visualization" or "infoviz".
 * __Tags__
   + All submissions are tagged
   + It is possible to retrieve all tags of submissions in currently ongoing sessions to build a tag-cloud
   + REST api
     * GET on _http://server.url:8000/ongoingtags_: returns all tags of submissions in ongoing sessions
 * __Keywords__
    + All submissions have author keywords
    + It is possible to retrieve all keywords of submissions in currently ongoing sessions to build a tag-cloud
    + REST api
      * GET on _http://server.url:8000/ongoingkeywords_: returns all keywords of submissions in ongoing sessions
     
     
###Events
The glance server uses [socket.io](http://socket.io) to send messages to the client.
Import the socket.io script (when HTML is served from node.js)

    <script src="/socket.io/socket.io.js"></script>
    
To connect

    var socket = io.connect("http://"+window.location.hostname, {port: 8000});
    
Now it is possible to listen to the following events

  * _tilesUpdated_: is called whenever a new filter is applied to the server
  * _tick_: is called with a configurable time interval and used to synchronise the "slideshows" of the displays. The data given with the tick event is an integer with the tick count.
  
Example:

    socket.on('tick', function(count) {
        console.log("Tick " + count;)
    });
    
    socket.on('tilesUpdated', function(data) {
        $.get('/tiles', function(tiles) {
            console.log("Filters updated!");
            console.log(data);
        });
    });
        
### Mobile Interface

The main file for the mobile interface is located under glance/mobile/phone.html

Once the server is running you can use it to post filters and view submissions related to them.

Once submissions are being display, a tap event on the tile triggers the function to send the selected submission ID to the future Obj-C function to add to the schedule on the iOS app.

    function addSubmission(id){
        alert("called iOS");
    }

As explained here https://developer.apple.com/library/mac/#documentation/AppleApplications/Conceptual/SafariJSProgTopics/Tasks/ObjCFromJavaScript.html#//apple_ref/doc/uid/30001215-BBCBFJCD , we should use this function to communicate both apps.

Currently it only offers "add" capabilities but more will come in the future.




