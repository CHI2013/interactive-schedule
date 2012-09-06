{exec} = require 'child_process'

srcDirs = "client_src/*"

task 'build', 'Build client application file from clientsrc files', ->
  exec 'coffee -o html/lib --compile ' + srcDirs, (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    console.log 'Build Done.'
    
task 'monitor', 'Build and keep rebuilding client application file from clientsrc files', ->
  console.log 'Watching client source, press break to stop'
  exec 'coffee -o html/lib --compile --watch ' + srcDirs, (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    console.log 'Build Done.'