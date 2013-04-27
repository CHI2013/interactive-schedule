var fingers = {};

function clearFingers() {
    var now = new Date();
    for (var finger in fingers) {
        if (fingers.hasOwnProperty(finger)) {
            if((now.getTime() - fingers[finger].timestamp.getTime()) > 200) {
                fingers[finger].div.remove();
                delete fingers[finger];
            }
          }
    };
};

$(document).ready(function() {

    var socket = io.connect("http://" + window.location.hostname, {
        port: 8000
    });
    
    window.setInterval(clearFingers, 200);
    
    
    socket.on('finger', function(data) {
        if (fingers[data.id] == undefined) {
            fingers[data.id] = {};
            fingers[data.id].div = $('<div class="pointer" style="width:100px; height: 100px; position:absolute; top: 10px; left: 10px; background: -webkit-radial-gradient(center, ellipse cover, rgba(0,0,0,1) 0%,rgba(0,0,0,0) 70%,rgba(0,0,0,0) 100%);"></div>');
            $('body').append(fingers[data.id].div);
        } 
        fingers[data.id].timestamp = new Date();
        
        moveCircle(data.id, data.x,data.y,data.z);
        
    });
    
});

function moveCircle(id, x,y,z) {
    div = fingers[id].div
    div.css("left",x).css("top",y);
	div.css({
		width: z,
		height: z,
		left: x,
        top: y,
	}, 5000);
}