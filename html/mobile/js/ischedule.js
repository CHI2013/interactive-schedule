      $(document).bind("mobileinit", function(){
        $.extend(  $.mobile , {
          touchOverflowEnabled: true,
          orientationChangeEnabled: false
        })
      });
      //Go back to "More section on iOS"
      function closeISchedule(){
        NativeBridge.call('closeISchedule');
      }  

      //Apply style depending on platform, iOS or Android
      //Default is android, if not android loads iOS theme
      var ua = navigator.userAgent.toLowerCase();
      var isAndroid = ua.indexOf("android") > -1; //&& ua.indexOf("mobile");
      if(!isAndroid) {
        $($("link[rel=stylesheet]")[1]).attr({href : "css/ios.css"});
        $($("link[rel=stylesheet]")[2]).remove();
      }

      if(isAndroid){
        $.extend(  $.mobile , {
          hashListeningEnabled: false
        });

      $(document).on("pageinit","#home", function(){
        $('#more').css("display","none");
      });
      }

    //Global variable to pass the selected tile to the search page.
    var selectedTile = "";
    var justLoaded = true;
    var host;
  
    host = $(location).attr('href')
    host = host.substring(0, host.length - 17);

    function reload(){
       location.reload();
    }

  function postLog(message){
    console.log(message);
      $.post(host + "log",
      {
        "message": message
      });
    };

    $(document).on("pageinit","#tiles", function(){

    var isOnline=setInterval(function(){checkOnlineStatus()},1000);

    function checkOnlineStatus(){
        isOnline  = window.navigator.onLine;
        if(!isOnline){
          $( "#offlineMsg" ).popup( "option", "dismissible", false );
          $( "#offlineMsg" ).popup( "open" );
          $("#reload").css("visibility", "visible");
        }
        else{
          $( "#offlineMsg" ).popup( "close" );

        }
     return isOnline;
    }

    host = $(location).attr('href')
    host = host.substring(0, host.length - 17);

    var socket = io.connect(host, {port: 8000});
    //var socket = io.connect("http://92.243.30.77", {port: 8000});

    console.log(host);
    //visual tiles
    var tiles = $(".tile");
    //logical tiles
    var tilesData = [];

    //Logical structure for each tile data
    function Tile (id){
      this.id = id;
      this.text = "";
      this.total = 0;
      this.current = 0;
      this.submissionId = 0;
      this.submissions = {};
      this.isInSchedule = false;
    };

    Tile.prototype.reset = function(){
      this.text = "Filter videos";
      this.total = 0;
      this.current = 0;
      this.submissionId = 0;
      this.submissions = {};
      this.isInSchedule = false;
    };

    function init(){
      createTiles();
      loadData();
      postLog("loaded tiles page");
    };  

    function sync(){
      $.get('/tick', function(count){
       console.log("get tick");
       console.log(count);
        if(!count.isEmpty)
         {
          for(var id in count)
          {
            updateTile(id, count[id]);
            for(var i = 0; i<tiles.length;i++)
            {
              if(id === tiles[i].getAttribute("id"))
              {
                $('#'+id).fadeTo(250, 0.5, function() {
                  // Animation complete.
                 });
                $('#'+id).fadeTo(250, 1, function() {
                  // Animation complete.
                 });
              }
            }
          }
         }
      });
    }
    //Creates 8 Tile objects
    function createTiles(){
      var ids = ["A","B","C","D","E","F","G","H"];
      for (var i=0; i< ids.length; i++){
        var tile = new Tile(ids[i]);
        tilesData.push(tile);
      }
    };

    //Load existing JSON data from /tiles and assign it to logical tiles
    function loadData(){
      $.get('/tiles', function(data){
        var kind;
        for(var id in data){
          if(data[id].type === "filter" && data[id].hasOwnProperty("filter"))
          {
            var filter = data[id];
            for(var i = 0; i<tilesData.length; i++)
            { 
              var tile = tilesData[i];
              if(tile.id === filter.filter.tileId)
              { 
                tile.total = filter.total;
                tile.submissions = filter.filter.submissions;

                if (tile.total > 0){
                  tile.text = tile.submissions[tile.current].title;
                  tile.submissionId = mapId(tile.submissions[tile.current]._id);
                  tile.isInSchedule = checkStatus(tile.submissionId);
                }
              }
            }
          }
          kind = data[id].when;
        }
        colorTiles(kind);
        showSubmissions();

      });
    };

    function colorTiles(kind){
      if(kind === "session"){

        $('#A').removeClass("blue");
        $('#B').removeClass("blue");
        $('#C').removeClass("green");
        $('#D').removeClass("green");
        $('#E').removeClass("red");
        $('#F').removeClass("red");
        $('#G').removeClass("orange");
        $('#H').removeClass("purple");


        $('#A').addClass("blue");
        $('#B').addClass("green");
        $('#C').addClass("red");
        $('#D').addClass("orange");
        $('#E').addClass("light_purple");
        $('#F').addClass("light_purple");
        $('#G').addClass("light_purple");
        $('#H').addClass("light_purple");
      }
      else{

        $('#A').removeClass("blue");
        $('#B').removeClass("green");
        $('#C').removeClass("red");
        $('#D').removeClass("orange");
        $('#E').removeClass("light_purple");
        $('#F').removeClass("light_purple");
        $('#G').removeClass("light_purple");
        $('#H').removeClass("light_purple");

        $('#A').addClass("blue");
        $('#B').addClass("blue");
        $('#C').addClass("green");
        $('#D').addClass("green");
        $('#E').addClass("red");
        $('#F').addClass("red");
        $('#G').addClass("orange");
        $('#H').addClass("purple");
      }
    }

    //Load logical tiles' data into visual tiles
    function showSubmissions(){
      for(var i = 0; i< tilesData.length; i++)
      {
        var tile = tilesData[i];
        if(tile.total > 0 && tile.id == tiles[i].getAttribute(
            "id"))
          {
          //tiles is the visual tiles, tilesData are the logical tiles
          if(justLoaded){
            tiles[i].innerHTML = "Syncing with display";
          }
          else
            tiles[i].innerHTML = tile.text;
          tiles[i].setAttribute("submissionId", tile.submissionId);
          tiles[i].setAttribute("total", tile.total);
          tiles[i].setAttribute("isInSchedule", tile.isInSchedule);
          tiles[i].setAttribute("current", tile.current);
          
          if(tile.isInSchedule === true){
              $('#'+tile.id).toggleClass("check");
            }
        }
      }
      sync();
      justLoaded = false;
    };

  //Update logical tiles then visual tiles
    function updateTile(tileId, index, status){      
      for(var i = 0; i< tilesData.length; i++)
      {
        var tile = tilesData[i];
        if(tile.id === tileId)
        {
          index = index % tile.total;
          //Update logical tiles
          //assign new text, schedule_status and id to logical tile
          tile.text= tile.submissions[index].title;
          tile.submissionId = mapId(tile.submissions[tile.current]._id);
          if(status === true || status === false)
          tile.isInSchedule = status;
          else
          tile.isInSchedule = checkStatus(tileId);
     
          //assign new current value to logical tile
          tile.current = index;

          //update visual tiles
          //tiles is the visual tiles, tilesData are the logical tiles
          tiles[i].innerHTML = tile.text;
          tiles[i].setAttribute("submissionId", tile.submissionId);
          tiles[i].setAttribute("current", tile.current);

          if(tile.isInSchedule){
            tiles[i].setAttribute("isInSchedule", true);
            $('#'+tile.id).addClass("check");
          }
          else{
            tiles[i].setAttribute("isInSchedule", false);
            $('#'+tile.id).removeClass("check");
          }
        }
      }
    };

    //function called after we iterate through all session events
    function doneTile(tileId,index){
      tile = tilesData[index];
      tile.reset();
      tiles[index].innerHTML = tile.text;
      tiles[index].setAttribute("submissionId", tile.submissionId)
      tiles[index].setAttribute("total", tile.total)
    };

    //Function triggered by the server every X milliseconds
    socket.on('tick', function(count) {
        console.log("tick");
        console.log(count);
        if(!count.isEmpty)
         {
          for(var id in count)
          {
             updateTile(id, count[id]);
            for(var i = 0; i<tiles.length;i++)
            {
              if(id === tiles[i].getAttribute("id"))
              {
                $('#'+id).fadeTo(250, 0.5, function() {
                  // Animation complete.
                 });
                $('#'+id).fadeTo(250, 1, function() {
                  // Animation complete.
                 });
              }
            }
          }
         }
    });


//When tapping a tile it toggle's the current display submission status on the schedule
    $(".tile").on("vclick", function(){
        var submissionId = $(this).attr("submissionid");
        var isInSchedule = $(this).attr("isInSchedule");
        var tileId = $(this).attr("id");
        var index = $(this).attr("current");
        var text = $(this).text();

        if(text === "Filter videos"){
            selectedTile = tileId;
            $.mobile.changePage("search.html", "slide", true, true);
            postLog("Loaded search page " + tileId);

        }
        else if( text === "Syncing with display"){
           return ;
        }
        else
          if (isInSchedule === "true") {
              if(isAndroid){
                AndroidBridge.togglePaperFavorite(submissionId, false);
                updateTile(tileId, index, false);
                postLog("Removed from schedule on Android " + submissionId);
              }
              else{
                NativeBridge.call('removeFromSchedule',submissionId,updateTile(tileId,index,false));
                updateTile(tileId, index, false);
                postLog("Removed from schedule on iOS " +  submissionId);
              }
          }
          else if(isInSchedule === "false"){
              if(isAndroid){
                AndroidBridge.togglePaperFavorite(submissionId, true);
                updateTile(tileId, index, true);
                postLog("Added to schedule on Android " + submissionId);
              }
              else{
                NativeBridge.call('addToSchedule',submissionId,updateTile(tileId,index,true));
                updateTile(tileId, index, true);
                postLog("Added to schedule on iOS " + submissionId);
              }
          };
    });

/*
 Maps IDs from the couchDB database to the PCS databse, required to interact with iOS app 
*/
  function mapId(id){
      if(id){
        id = id.replace(/pn/,"chi")
            .replace(/crs/,"cr")
            .replace(/tochi/,"to")
            .replace(/case/,"cs")
            .replace(/pan/,"pl")
            .replace(/sig/,"si");
        return id;
      }
      else return false;
    };

/*
Calls native iOS function call to check if submission is in schedule
Returns true or false depending on bridge call result which can be:
"Error","True","False" 
*/
  function checkStatus(id){
    var status = false;
    if(isAndroid){
      status = AndroidBridge.isPaperFavorite(id);
    }
    else{
      status = NativeBridge.call('isInSchedule', id, thisiscallback);
    }
    // temp fix for testing on web
    if(status === undefined)
      return false;
    //fix for string return value
    if(status === "True")
        status =  true;
    return status;
    };

    //Function called after a new filter is posted to server
    //Populates arrays with all titles for each filter
    socket.on('tilesUpdated', function(data) {
          loadData();
    });

    //update colors between session and breaks
    socket.on('newTile',function(data){
      console.log(data);
      justLoaded = true;
      loadData();
    });


    socket.on('doneTile', function(data) { 
        for(var i = 0; i<tilesData.length;i++)
        {
          if(data.tileId === tilesData[i].id)
          { 
            doneTile(data.tileId, i);
          }
        }
    });

    //Called at load
    init();

    });


///////code to from search page///
  $(document).on("pageinit","#search", function(){
    // all selected titles from the search interface
    var result = "";
    // all selected ids from the search interface
    var letterCodes= [];
    $( document ).on( "listviewbeforefilter", '#autocomplete', function ( e, data ) {
        var $ul = $( this ),
            $input = $( data.input ),
            value = $input.val(),
            html = "";
        $ul.html( "" );
        if ( value && value.length > 2 ) {
            $ul.html( "<li><div class='ui-loader'><span class='ui-icon ui-icon-loading'></span></div></li>" );
            $ul.listview( "refresh" );
            $.ajax({
                url:host+"autocompletelist",
                dataType: "jsonp",
                crossDomain: true,
                data: {
                    substring: $input.val()
                }
            })
            .then( function ( response ) {
              postLog("Searched for " + value);
              result = value;
              console.log(response);
                $.each( response, function ( i, val ) {
                  $.each(val, function(j){
                    html += "<li  class='result' data-source=" + i + " data-ids=" + val[j] +">" + j + "<span class='ui-li-count'>" + val[j].length + "</span></li>";
                  })
                });
                $ul.html( html );
                $ul.listview( "refresh" );
                $ul.trigger( "updatelayout");
            });
        }
    });

    $("#autocomplete").listview({
      autodividers: true,
      autodividersSelector: function ( li ) {
          var out = $(li).attr('data-source');
          return out;
      }
    });

    $("#autocomplete").delegate('.result', 'vclick', function(){
      $(this).toggleClass("selected");
   //   result = "";
      letterCodes = [];
      if($(".selected").exists()){
         $("#post").css("visibility","visible");
         var $selected = $(".selected");
         for(var i = 0; i< $selected.length; i++){
          var temp = $selected[i].innerText;
       //   result += temp.substring(0, temp.length - 1) + " ";
          letterCodes = letterCodes.concat(getCodes($selected[i]));
         }
      }
      else{
         $("#post").css("visibility","hidden");
      }
    });

    $('#post').on("click", function(){
      postFilter(result);
      $.mobile.changePage("tiles.html", "slide", true, true);
    });

  function getCodes(item){
    var ids = $(item).attr("data-ids").split(",");
    return ids;
  }

  function postFilter(result){
      $.post(host + "filters", 
      {
        "filterName": result,
        "tile": selectedTile,
        "letterCode": letterCodes
      },
      function(data, status)
      {
        console.log("Updated session: " + data);
        console.log(data);
        postLog("Posted Filter " + result);
      });
  };

    $.fn.exists = function () {
      return this.length !== 0;
    }
  });