sh wipe_database.sh
coffee load.coffee json/submissions.json json/sessions.json json/schedule.json json/interactivity.json
cd couchdb_designs
sh post_designs.sh
cd ..