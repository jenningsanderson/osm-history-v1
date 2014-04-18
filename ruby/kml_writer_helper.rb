require 'geo_ruby/kml'
require 'time'

class KMLAuthor

  def initialize(filename)
    @filename = filename.dup #Getting weird frozen error...
    unless @filename =~ /\.kml$/
      @filename << '.kml'
    end
    @openfile = File.open(@filename, 'w')
  end

  def write_header(title)
    @openfile.write "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    @openfile.write "<kml xmlns=\"http://earth.google.com/kml/2.1\">\n"
    @openfile.write "<Document>\n<name>#{title}</name>\n\n"
  end

  def write_folder(folder)
    @openfile.write "<Folder>\n<name>#{folder[:name]}</name>"
    unless folder[:features].empty?
      folder[:features].each do |feature|
        write_placemark(feature)
      end
    end
    @openfile.write "</Folder>\n\n"
  end

  def write_placemark(feature)
    @openfile.write "<Placemark>\n"
    @openfile.write "\t<name>#{feature[:name]}</name>\n"
    if feature.has_key? :style
      @openfile.write "<styleUrl>##{feature[:style].to_s}</styleUrl>"
    end
    if feature.has_key? :time
      @openfile.write "<TimeStamp>\n"
      @openfile.write "\t<when>#{feature[:time].iso8601}</when>\n"
      @openfile.write "</TimeStamp>"
    end
    @openfile.write "\t"+feature[:geometry].as_kml
    @openfile.write "</Placemark>\n\n"
  end


  def write_footer
    @openfile.write("\n</Document>\n</kml>")
  end

  #Below here is only style information
  def add_style(style)
    @openfile.write "<Style id=\"#{style[:id]}\">"
    if style.has_key? :polygon
      @openfile.write "<PolyStyle>"
      @openfile.write "\t<color>#{style[:polygon][:color]}</color>"
      @openfile.write "</PolyStyle>"
    end
    @openfile.write "</Style>"
  end

  def add_default_styles
    @openfile.write %Q{
    <Style id="transBluePoly">
      <LineStyle>
        <width>1.5</width>
      </LineStyle>
      <PolyStyle>
        <color>7dff0000</color>
      </PolyStyle>
    </Style>
    <visibility>0</visibility>

    <Style id="Before">
      <IconStyle>
        <scale>0.4</scale>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/paddle/grn-blank-lv.png</href>
        </Icon>
      </IconStyle>
      <LabelStyle>
        <scale>0</scale>
      </LabelStyle>
      <LineStyle>
        <color>ff5bbd00</color>
        <width>1.4</width>
      </LineStyle>
    </Style>

    <Style id="During">
      <IconStyle>
        <scale>0.4</scale>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/paddle/red-circle-lv.png</href>
        </Icon>
      </IconStyle>
      <LabelStyle>
        <scale>0</scale>
      </LabelStyle>
      <LineStyle>
        <color>ff1515a6</color>
        <width>1.4</width>
      </LineStyle>
    </Style>

    <Style id="After">
      <IconStyle>
        <scale>0.4</scale>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/paddle/ylw-blank-lv.png</href>
        </Icon>
      </IconStyle>
      <LabelStyle>
        <scale>0</scale>
      </LabelStyle>
      <LineStyle>
        <color>ff7fffff</color>
        <width>1.4</width>
      </LineStyle>
    </Style>
  }
  end

end
