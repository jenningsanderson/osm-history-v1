'''
Write a geojson feature collection
'''

require 'mongo'
require 'json'
require 'optparse'

class GeoJSONWriter
  attr_reader :filename

  def initialize(filename)
    @filename = filename.dup #Getting weird frozen error...
    unless @filename =~ /\.geojson$/
      @filename << '.geojson'
    end
    @open_file = File.open(@filename, 'w')
  end

  def add_options(options_hash)
    @options = options_hash
  end

  def write_header
    @open_file.write "{\"type\" : \"FeatureCollection\","
    unless @options.nil?
      @open_file.write @options.to_json
    end
    @open_file.write "\"features\" :["
  end

  def write_feature(geometry, properties)
    @open_file.write "{"
    @open_file.write "\"type\" : \"Feature\", "
    @open_file.write "\"geometry\" : #{geometry.to_json},"
    @open_file.write "\"properties\" : #{properties.to_json}"
    @open_file.write "},"
  end

  def literal_write_feature(feature)
    @open_file.write(feature)
    @open_file.write(",")
  end

  def write_footer
    #Close the file and then truncate the last comma
    @open_file.close()
    File.truncate(@filename, File.size(@filename) - 1) #Remove the last comma

    #Open the file again and close the object
    File.open(@filename,'a') do |file|
      file.write(']}')
    end
  end
end #end class
