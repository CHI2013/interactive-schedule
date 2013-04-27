$(document).ready(function() {

    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });
   
    socket.on('finger', function(data) {
        console.log(data);
    });
    
});
