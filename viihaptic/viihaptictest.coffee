osc = require 'osc-min'
udp = require "dgram"

sock = udp.createSocket "udp4", (msg, rinfo) =>
  try
    oscMsg = osc.fromBuffer msg
    console.log oscMsg
    return true
  catch error
    console.log error
    return console.log "invalid OSC packet"

sock.bind 3333