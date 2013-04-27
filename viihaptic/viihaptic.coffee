osc = require 'osc-min'
udp = require "dgram"

class exports.ViiHaptic
    
    constructor: (iosocket) ->
        sock = udp.createSocket "udp4", (msg, rinfo) =>
          try
            oscMsg = osc.fromBuffer msg
            if oscMsg.elements[0]?
                element = oscMsg.elements[0]
                if element.args? and element.args.length > 4
                    state = element.args[0].value
                    id = element.args[1].value
                    x = element.args[2].value * 1080
                    y = (element.args[3].value * 1095) + 825
                    z = element.args[4].value
            
                    iosocket.sockets.emit 'finger', {'id': id, 'x': x, 'y': y, 'z': z, 'state': state}
                    
            return true
          catch error
            return console.log "invalid OSC packet", error
        sock.bind 3333
    