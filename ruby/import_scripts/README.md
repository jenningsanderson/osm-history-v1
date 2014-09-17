Import Scripts
=============================






###import_users.rb
	Usage: ruby import_users.rb -d DATABASE  [-l LIMIT]
		This will import users specifically from the changesets found in the desired database
	
	Specific options:
	    -d, --database Database Name     Name of Database (Haiti, Philippines)
	    -l, --limit [LIMIT]              [Optional] Limit of users to parse
	    -h, --help                       Show this message

This script performs an **upsert** on the user collection for a given database.  It collects users from the changesets collection and then hits the api for each one, upsetting their details to the Mongo collection.

