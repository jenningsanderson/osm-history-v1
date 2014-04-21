require 'mongo'
require 'optparse'
require 'json'
require 'time'
require 'georuby'
require 'geo_ruby/geojson'
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
    @openfile.write "<Folder>\n<name>#{folder[:name]}</name>\n"

    unless folder[:folders].nil?
      folder[:folders].each do |inner_folder|
        write_folder(inner_folder)
      end
    else
      unless folder[:features].empty?
        folder[:features].each do |feature|
          write_placemark(feature)
        end
      end
    end
    @openfile.write "</Folder>\n\n"
  end

  def write_placemark(feature)
    @openfile.write "<Placemark>\n"
    unless feature[:name].nil?
      @openfile.write "\t<name>#{feature[:name]}</name>\n"
    end
    if feature.has_key? :style
      @openfile.write "\t<styleUrl>#{feature[:style]}</styleUrl>\n"
    end
    if feature.has_key? :extended
      @openfile.write "\t<ExtendedData>\n"
      feature[:extended].each do |k,v|
        @openfile.write "\t\t<Data name=\"#{k}\">#{v}</Data>\n"
      end
      @openfile.write "\t</ExtendedData>\n"
    end
    if feature.has_key? :desc
      if feature.has_key? :link
        @openfile.write "\t<description>\n\t\t#{feature[:desc]}\n<![CDATA[<img src=\"#{feature[:link]}\">]]></description>\n"
      else
      @openfile.write "\t<description>\n\t\t#{feature[:desc]}\n\t</description>\n"
      end
    end
    if feature.has_key? :time
      @openfile.write "\t<TimeStamp>\n"
      @openfile.write "\t\t<when>#{feature[:time].iso8601}</when>\n"
      @openfile.write "\t</TimeStamp>"
    end
    if feature.has_key? :gxTrack
      @openfile.write %Q{\t<gx:Track>
      \t\t<altitudeMode>absolute</altitudeMode>
      \t\t<when>#{feature[:gxTrack][:start][:time].iso8601}</when>
      \t\t<when>#{feature[:gxTrack][:end][:time].iso8601}</when>
      \t\t<gx:coord>#{feature[:gxTrack][:start][:pos]}</gx:coord>
      \t\t<gx:coord>#{feature[:gxTrack][:end][:pos]}</gx:coord>
      \t</gx:Track>}
    end

    unless feature[:geometry].nil?
      @openfile.write "\t"+feature[:geometry].as_kml
    end
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

  def random_hex_color
    (0..5).map{ rand(16).to_s(16) }.join
  end

  def generate_random_styles(number_of_styles)

    number_of_styles.times do |id|
      #Generate a random hex color
      color = random_hex_color

      #Open the Style
      @openfile.write "<Style id=\"r_style_#{id}\">\n"

      #Point
      @openfile.write %Q{\t<IconStyle>
        <color>77#{color}</color>
         <scale>.5</scale>
         <Icon>http://maps.google.com/mapfiles/kml/paddle/wht-blank-lv.png</Icon>
          <LabelStyle>
            <scale>0</scale>
          </LabelStyle>
    </IconStyle>\n}

      #Line
      @openfile.write %Q{\t<LineStyle>
        <color>77#{color}</color>
        <width>1.5</width>
    </LineStyle>\n}

      #Poly
      @openfile.write %Q{\t<PolyStyle>
        <color>AA#{color}</color>
        <BalloonStyle>
          <text>&lt;h1&gt;$[name]&lt;/h1&gt;$[description]</text>
          <bgColor>ffd5efff</bgColor>
        </BalloonStyle>
    </PolyStyle>\n}
      @openfile.write "</Style>\n\n"
    end
  end

  def write_3_bin_styles
    @openfile.write %Q{
    <Style id="before">
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

    <Style id="during">
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

    <Style id="after">
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
    </Style>}
  end
end
