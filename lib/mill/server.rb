require 'sinatra/base'
require 'addressable/uri'
require 'path'
require 'pp'

$LOAD_PATH.unshift "#{ENV['HOME']}/Projects/mill/lib"
require 'mill/extensions/path'

class Mill

  class Server < Sinatra::Application

    get '*' do
      uri_path = Addressable::URI.parse(params[:splat].first).normalized_path
      path = Path.new(settings.public_dir) / Path.new(uri_path).relative_to('/')
      path /= 'index' if uri_path[-1] == '/'
      if path.directory?
        log.info "#{uri_path} => [redirect] #{uri_path}"
        return redirect "#{uri_path}/"
      elsif path.file?
        log.info "#{uri_path} => [file] #{path}"
        return send_file(path)
      elsif path.extname.empty?
        %w{.html .jpg}.each do |extname|
          p = path.add_extension(extname)
          if p.file?
            log.info "#{uri_path} => [file] #{p}"
            return send_file(p)
          end
        end
      end
      log.info "#{uri_path} => [not found]}"
      halt 404, 'not found'
    end

  end

end