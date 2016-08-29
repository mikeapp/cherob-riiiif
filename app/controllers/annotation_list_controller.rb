class AnnotationListController < ApplicationController

  KEYS = ['Surface Note', 'User', 'Color Type', 'Note Start', 'Linked Images']

  def show
    project = params[:project]
    object = params[:object]
    list = Hash.new
    list['@context'] = 'http://iiif.io/api/presentation/2/context.json'
    list['@id'] = "http://127.0.0.1:3000/annotationlist/#{project}/#{object}"
    list['@type'] = 'sc:AnnotationList'
    list['resources'] = load_annotations(project,object)
    render json: list
  end

  private

  def load_annotations(project, object)
    annotations = []
    path = "/Users/mikea/code/ruby/cherob-riiif/examples/#{project}/#{object}.jpg/Note/"
    puts path
    Dir.glob(path + 'SurfaceNote2D*').each do |f|
      data =  File.read(f)
      annotation = to_annotation(project, object, f, note_to_hash(data))
      annotations.push(annotation)
    end
    annotations
  end

  def note_to_hash(data)
    note_hash = Hash.new
    key = nil
     data.each_line do |line|
       new_key = false
       KEYS.map { |start|
         if line.start_with?(start)
           new_key = true
           key = start
         end
       }
       next if new_key unless key == 'Surface Note'
       if key == 'Surface Note'
          line = line[line.index('Image Coordinate Start ('), line.length]
          line.gsub!(/[A-Za-z ]/, '')
          line.gsub!(/\)\(/,',')
          line.gsub!(/[)(]/,'')
          line.gsub!(/[\)\(]/,'')
          x1, y1, x2, y2 = line.split(',')
          xs = [x1.to_i, x2.to_i]
          ys = [y1.to_i, y2.to_i]
          x = xs.min
          y = 3281-ys.max
          w = (x1.to_i - x2.to_i).abs
          h = (y1.to_i-y2.to_i).abs
          note_hash['xywh'] = "#{x},#{y},#{w},#{h}"
       else
         note_hash[key] ||= Array.new
         note_hash[key].push(line.strip!)
       end
     end
    note_hash
  end

  def to_annotation(project, object, filename, note_hash)
    html = "<span>"
    note_hash['Note Start'].each { |t| html += t }
    note_hash['Linked Images'].each { |i|
      i.gsub!('../images/','')
      img_url = "http://127.0.0.1:3000/#{i}"
      html += "<img src=\"#{img_url}\"/>"
    }
    color = "black"
    color = note_hash['Color Type'][0] if note_hash['Color Type']

    oa = Hash.new
    oa['@id'] = "http://127.0.0.1/annotation/#{project}/#{object}/#{SecureRandom.uuid}"
    oa['@type'] = 'oa:Annotation'
    oa['motivation'] = 'sc:commenting'
    oa['on'] = "http://127.0.0.1:3000/canvas/#{object}#xywh=#{note_hash['xywh']}"
    oa['stylesheet'] = {
        "@type": ["oa:CssStyle", "cnt:ContextAsText"],
        "chars": ".red {color: red;}"
    }
    oa['resource'] = {
        "@type": "cnt:ContentAsText",
        "format": "text/html",
        "language": "en",
        "chars": html
    }
    oa
  end

end
