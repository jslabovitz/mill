require 'sinatra/base'
require 'addressable/uri'
require 'path'
require 'pp'

$LOAD_PATH.unshift "#{ENV['HOME']}/Projects/mill/lib"
require 'mill/extensions/path'

class Mill

  class Server < Sinatra::Application

    PublicFolder = 'site'

    get '*' do
      uri_path = Addressable::URI.parse(params[:splat].first).normalized_path
      path = Path.new(PublicFolder) / Path.new(uri_path).relative_to('/')
      path /= 'index' if uri_path[-1] == '/'
      log.info "#{uri_path} => #{path}"
      if path.directory?
        return redirect "#{uri_path}/"
      elsif path.file?
        return send_file(path)
      elsif path.extname.empty?
        %w{.html .jpg}.each do |extname|
          p = path.add_extension(extname)
          return send_file(p) if p.file?
        end
      end
      halt 404, 'not found'
    end

  end

end