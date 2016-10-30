#!/usr/bin/env ruby
#DOESNT WORK ANYMORE UR BAD SON
require 'sinatra'
require 'rest-client'
require 'open-uri'
require 'viddl-rb'
require 'video_info'

class Rack::Handler::WEBrick
    class << self
        alias_method :run_original, :run
    end
    def self.run(app, options={})
        options[:DoNotReverseLookup] = true
        run_original(app, options)
    end
end

url = "http://youtube.com"
last_link = "/youtube"
param = nil
error = nil
set :port, 4567
set :public_folder, 'public'


get '/' do
  send_file 'public/home.html'
end


get '/youtube' do
	content_type = ''
	body = open(url) {|f|
  		content_type = f.content_type    
  		f.read
	}
end
	
get '/error' do
	"#{error}"
end

get '/clear' do
  correct_pswrd = "linux123"
  pswrd = params[:auth]
  delCount = 0
  file_count = 0
  oldest_file_date = 0.0

  if pswrd == correct_pswrd then
    Dir["public/*.mp4"].each do |f|
      file_count += 1
      if (Time.now - File.stat(f).mtime).to_i / 86400.0 > oldest_file_date.to_f then
          oldest_file_date = (Time.now - File.stat(f).mtime).to_i / 86400.0
        end

      if (Time.now - File.stat(f).mtime).to_i / 86400.0 >= 1.0 then
        File.delete(f)
        delCount+=1
      end
    end
    "#{delCount} File(s) deleted out of #{file_count} total files. Oldest file is now #{oldest_file_date} days old!"
  else
    "Authentication failed."
  end
end

get '/watch' do
    v = params[:v]
    watchurl = url + "/watch?v=" + v
    video_stuff = VideoInfo.new("#{watchurl}")

    filename = ViddlRb.get_names("#{watchurl}")
    filename = filename[0]
    filename = File.basename(filename,File.extname(filename))
    newname = filename
    newname = newname.tr('[','(')
    newname = newname.tr(']',')')
    newname = newname.tr("'","")
    newname = newname.tr('_','')
    newname = newname.tr('#','')

    if File.exist?("public/" +newname+".mp4") == false then
      system("viddl-rb #{watchurl} --quality *:360:mp4 --downloader aria2c --save-dir C:/Users/jmckay/Desktop/RubyDev/public/")
      File.rename("public/#{filename}.mp4", "public/#{newname}.mp4")
    end


    #<video width='1280' height='720' controls>
    # <source src='#{newname}.mp4' type='video/mp4'>
    #Your browser does not support the HTML5 video tag!
    #</video>

    "<html>
    <body>
    <h1>#{filename}</h1>
    <form action='#{last_link}'>
    <input type='submit' value='Go back to Youtube'/>
    </form>
    
    <div>
    <center>
    <embed src='#{newname}.mp4' width='720' height='480' scale='tofit' autoplay='false'>

    <object data='#{newname}.mp4' width='720' height='480'>
    </object></center>
    </div>

    <h2><u>Description</u><h2>
    <small>#{video_stuff.description}</small>
    </body>
    </html>"
end

not_found do  
    param = request.path + "?" + request.query_string
    RestClient.get(url + param)
end
