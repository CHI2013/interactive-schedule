sh wipe_database.sh
coffee load.coffee json/submissions-2013-1-4-11-32-5.json json/sessions-2013-1-4-11-32-11.json json/schedule-2013-1-4-11-32-13.json
cd couchdb_designs
sh post_designs.sh
cd ..