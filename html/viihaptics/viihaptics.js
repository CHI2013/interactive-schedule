$(document).ready(function() {

    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });
    
    socket.on('finger', function(data) {
        moveCircle(data.x,data.y,data.z);
    });
    
});

function moveCircle(x,y,z) {
    $("#pointer").css("left",x).css("top",y);
}