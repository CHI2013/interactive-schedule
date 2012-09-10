glance
======

Description
-----------

glance is the back-end for the new CHI2013 papers-at-a-glance system.

Installing and running
----------------------

You'll need [node.js](http://nodejs.org), [CoffeeScript](http://coffeescript.org) and [CouchDB](http://couchdb.apache.org) to run the server.

When CouchDB is installed create a database in it (e.g. named chi2013). 

Now run 'npm install' in the root of glance
Now go to the folder 'bootstrap_scripts' and run 

    'coffee load_papers_and_sessions.coffee paper_submissions.csv paper_sessions.csv' (Get the data from Clemens or Arvind)

Now you need to add a view to the database so do the following:
Navigate to the couchdb_design folder and fire off the shellscript in there

    sh post_designs.sh

To compile the (now very simple client code) in the root of glace run 'cake build'

Change the config.json to point at the right database in CouchDB

NOW you can run the server by from the glance root:

    coffee glance.coffee config.json

The server will now run on http://localhost:8000

If you just browse there nothing will happen but http://localhost:8000/session should dump all sessions.

You can see a bit of interaction if you browser to http://localhost:8000/phone.html and look at the javascript console output. (The functionality of mobile.html is implemented in phone.coffee).
If you post a new filter

    curl -X POST http://localhost:8000/filters -H "Content-Type: application/json" -d '{"tags": ["visualization", "infoviz"]}'
    
    
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
     * GET on _http://server.url:8000/ongoingsessions_: returns all sessions that are currently ongoing (time hardcoded in server for now)
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
        
  

