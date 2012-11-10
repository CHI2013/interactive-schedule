sh wipe_database.sh
coffee load_papers_and_sessions.coffee paper_submissions.csv paper_sessions.csv
cd couchdb_designs
sh post_designs.sh
cd ..