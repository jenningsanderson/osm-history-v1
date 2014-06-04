var search_data = {"index":{"searchIndex":["getchangesetgeometries","getnodegeometries","invalidapierror","mongo","osmapihitter","osmchangeset","osmgeojsonmongo","osmhistoryanalysis","object","rgeo","userwithchangesets","visualizechangesetsbyuser","parser()","add_node()","add_relation()","add_way()","bounding_box_envelope()","calculate_overlap()","changesets_geometries()","connect_to_mongo()","convert_to_rgeo()","extract_bounding_box()","file_stats()","fix_types()","get_changeset_nodes()","get_changesets()","get_geometry()","get_user_count_by_hour()","hit_api()","hit_api()","hit_mongo()","hit_mongo()","hit_nodes_collection()","insert_to_mongo()","load_job_geomtries_from_csv()","load_tiles_history_from_csv()","new()","new()","new()","new()","new()","new()","new()","parse_response()","parse_to_collection()","process_geometries()","read_notes_to_mongo()","read_pbf_to_mongo()","reset_parser()","set_query_times()","write_changeset_kml()","write_geojson_jobs()","write_user_bounding_envelopes()","write_user_changesets()","write_user_contributions_by_day()"],"longSearchIndex":["getchangesetgeometries","getnodegeometries","invalidapierror","mongo","osmapihitter","osmchangeset","osmgeojsonmongo","osmhistoryanalysis","object","rgeo","userwithchangesets","visualizechangesetsbyuser","osmgeojsonmongo#parser()","osmgeojsonmongo#add_node()","osmgeojsonmongo#add_relation()","osmgeojsonmongo#add_way()","userwithchangesets#bounding_box_envelope()","object#calculate_overlap()","userwithchangesets#changesets_geometries()","osmhistoryanalysis#connect_to_mongo()","getnodegeometries#convert_to_rgeo()","osmchangeset#extract_bounding_box()","osmgeojsonmongo#file_stats()","osmchangeset#fix_types()","getchangesetgeometries#get_changeset_nodes()","userwithchangesets#get_changesets()","osmgeojsonmongo#get_geometry()","object#get_user_count_by_hour()","osmapihitter::hit_api()","osmchangeset#hit_api()","object#hit_mongo()","visualizechangesetsbyuser#hit_mongo()","getnodegeometries#hit_nodes_collection()","osmchangeset#insert_to_mongo()","object#load_job_geomtries_from_csv()","object#load_tiles_history_from_csv()","getchangesetgeometries::new()","getnodegeometries::new()","osmchangeset::new()","osmgeojsonmongo::new()","osmhistoryanalysis::new()","userwithchangesets::new()","visualizechangesetsbyuser::new()","osmchangeset#parse_response()","osmgeojsonmongo#parse_to_collection()","userwithchangesets#process_geometries()","osmgeojsonmongo#read_notes_to_mongo()","osmgeojsonmongo#read_pbf_to_mongo()","osmgeojsonmongo#reset_parser()","osmhistoryanalysis#set_query_times()","object#write_changeset_kml()","object#write_geojson_jobs()","object#write_user_bounding_envelopes()","object#write_user_changesets()","object#write_user_contributions_by_day()"],"info":[["GetChangesetGeometries","","GetChangesetGeometries.html","",""],["GetNodeGeometries","","GetNodeGeometries.html","",""],["InvalidAPIError","","InvalidAPIError.html","",""],["Mongo","","Mongo.html","",""],["OSMAPIHitter","","OSMAPIHitter.html","",""],["OSMChangeset","","OSMChangeset.html","",""],["OSMGeoJSONMongo","","OSMGeoJSONMongo.html","",""],["OSMHistoryAnalysis","","OSMHistoryAnalysis.html","","<p>This is the main class for global variables &amp; common functions to the\nanalysis\n"],["Object","","Object.html","",""],["RGeo","","RGeo.html","",""],["UserWithChangesets","","UserWithChangesets.html","",""],["VisualizeChangesetsByUser","","VisualizeChangesetsByUser.html","","<p>Define bounding boxes and then find nodes within that box.  Export to\nGeoJSON\n"],["Parser","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-Parser","(file)","<p>Initialize the pbf parser from the file\n"],["add_node","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-add_node","(node)",""],["add_relation","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-add_relation","(relation)",""],["add_way","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-add_way","(way)",""],["bounding_box_envelope","UserWithChangesets","UserWithChangesets.html#method-i-bounding_box_envelope","()",""],["calculate_overlap","Object","Object.html#method-i-calculate_overlap","(res, country)","<p>Find the overlapping changesets, currently counts all changesets, not just\nby user\n"],["changesets_geometries","UserWithChangesets","UserWithChangesets.html#method-i-changesets_geometries","()",""],["connect_to_mongo","OSMHistoryAnalysis","OSMHistoryAnalysis.html#method-i-connect_to_mongo","(db='haiti',coll='nodes', host=nil, port=nil)","<p>Generic call for connecting to Mongo server with Error Handling,  returns\nan instance of the collection …\n"],["convert_to_rgeo","GetNodeGeometries","GetNodeGeometries.html#method-i-convert_to_rgeo","(georuby_polygon)",""],["extract_bounding_box","OSMChangeset","OSMChangeset.html#method-i-extract_bounding_box","()",""],["file_stats","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-file_stats","()",""],["fix_types","OSMChangeset","OSMChangeset.html#method-i-fix_types","()",""],["get_changeset_nodes","GetChangesetGeometries","GetChangesetGeometries.html#method-i-get_changeset_nodes","()",""],["get_changesets","UserWithChangesets","UserWithChangesets.html#method-i-get_changesets","()",""],["get_geometry","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-get_geometry","(coll, id)",""],["get_user_count_by_hour","Object","Object.html#method-i-get_user_count_by_hour","(res, dataset)",""],["hit_API","OSMAPIHitter","OSMAPIHitter.html#method-c-hit_API","(uris)","<p>Returns the hash payload of the input URI w.r.t API symbol.\n"],["hit_api","OSMChangeset","OSMChangeset.html#method-i-hit_api","()",""],["hit_mongo","Object","Object.html#method-i-hit_mongo","()","<p>Hit Mongo to get the changesets\n\n<pre>TODO: This is a duplicate function from other files, need to refactor, ...</pre>\n"],["hit_mongo","VisualizeChangesetsByUser","VisualizeChangesetsByUser.html#method-i-hit_mongo","(dataset = 'haiti', limit = 100, bbox = nil )",""],["hit_nodes_collection","GetNodeGeometries","GetNodeGeometries.html#method-i-hit_nodes_collection","()",""],["insert_to_mongo","OSMChangeset","OSMChangeset.html#method-i-insert_to_mongo","()",""],["load_job_geomtries_from_csv","Object","Object.html#method-i-load_job_geomtries_from_csv","(csv)","<p>Read in the Jobs &amp; Use RGeo Appropriately\n"],["load_tiles_history_from_csv","Object","Object.html#method-i-load_tiles_history_from_csv","(csv)","<p>Load and parse the tiles history export from the OSM TM DB\n"],["new","GetChangesetGeometries","GetChangesetGeometries.html#method-c-new","(changeset, database=FALSE)",""],["new","GetNodeGeometries","GetNodeGeometries.html#method-c-new","(user, database=FALSE)",""],["new","OSMChangeset","OSMChangeset.html#method-c-new","(id, type)",""],["new","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-c-new","(database, host, port)",""],["new","OSMHistoryAnalysis","OSMHistoryAnalysis.html#method-c-new","()","<p>Constructor: calls the query times function\n"],["new","UserWithChangesets","UserWithChangesets.html#method-c-new","(uid, db)",""],["new","VisualizeChangesetsByUser","VisualizeChangesetsByUser.html#method-c-new","()",""],["parse_response","OSMChangeset","OSMChangeset.html#method-i-parse_response","()",""],["parse_to_collection","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-parse_to_collection","(object_type, lim=nil)",""],["process_geometries","UserWithChangesets","UserWithChangesets.html#method-i-process_geometries","()",""],["read_notes_to_mongo","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-read_notes_to_mongo","(api_notes, lim=nil)",""],["read_pbf_to_mongo","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-read_pbf_to_mongo","(lim=nil)",""],["reset_parser","OSMGeoJSONMongo","OSMGeoJSONMongo.html#method-i-reset_parser","()","<p>If the function @parser.seek(0) worked, it would be better…\n"],["set_query_times","OSMHistoryAnalysis","OSMHistoryAnalysis.html#method-i-set_query_times","()","<p>Set the most common times for querying the database\n"],["write_changeset_kml","Object","Object.html#method-i-write_changeset_kml","(filename, cursor, db, title='KML FILE')",""],["write_geojson_jobs","Object","Object.html#method-i-write_geojson_jobs","(job_geometries)","<p>Write the job_geometries to a geojson file\n"],["write_user_bounding_envelopes","Object","Object.html#method-i-write_user_bounding_envelopes","(filename, cursor, db)",""],["write_user_changesets","Object","Object.html#method-i-write_user_changesets","(filename, cursor, db)",""],["write_user_contributions_by_day","Object","Object.html#method-i-write_user_contributions_by_day","(res, filename)",""]]}}