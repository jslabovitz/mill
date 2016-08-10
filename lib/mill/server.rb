module Mill

  class Server

    attr_accessor :root
    attr_accessor :multihosting
    attr_accessor :use_x_sendfile

    def initialize(root: '.', multihosting: false, use_x_sendfile: false)
      @root = Path.new(root)
      @multihosting = multihosting
      @use_x_sendfile = use_x_sendfile
    end

    def run(rack_params={})
      Rack::Server.start(rack_params.merge(app: self))
    end

    def call(env)
      request = Rack::Request.new(env)
      response = handle_request(request)
      response.finish
    end

    def handle_request(request)
      unless request.get? || request.head? || request.options?
        return error_response(:method_not_allowed)
      end
      uri, filename = parse_uri(request.url)
      # ;;warn "#{request.url} => #{filename}"
      unless filename_is_public?(filename)
        return error_response(:forbidden)
      end
      redirect_path = filename.add_extension('.redirect')
      if redirect_path.exist?
        return redirect_response_from_file(redirect_path, uri)
      end
      if filename.directory?
        return redirect_response(uri + '/')
      end
      unless (filename = find_filename(filename))
        return error_response(:not_found)
      end
      unless filename.readable?
        return error_response(:forbidden)
      end
      if request.get_header('HTTP_IF_MODIFIED_SINCE') == filename.mtime.httpdate
        return redirect_response(nil, :not_modified)
      end
      send_file_response(filename, :ok, request.get?)
    end

    private

    def parse_uri(uri)
      uri = Addressable::URI.parse(uri)
      path = Path.new(@root)
      if @multihosting
        host = Addressable::URI.unencode_component(uri.normalized_host).downcase
        host.sub!(/^(www|web).*?\./, '')
        path /= host
      end
      path /= Path.new(Addressable::URI.unencode_component(uri.normalized_path))
      path /= 'index.html' if path.to_s.end_with?('/')
      path = @root / path.relative_path_from('/')
      [uri, path]
    end

    def filename_is_public?(filename)
      filename.each_filename.to_a.find { |p| p.to_s.start_with?('.') } == nil
    end

    def find_filename(filename)
      ['', '.html', '.htm'].each do |extension|
        guessed_filename = filename.add_extension(extension)
        if guessed_filename.file? && guessed_filename.readable?
          return guessed_filename
        end
      end
      nil
    end

    def redirect_response_from_file(redirect_path, base_uri)
      uri, status = redirect_path.read.split(/\s+/)
      uri = Addressable::URI.parse(uri)
      redirect_response((base_uri + uri).to_s, status)
    end

    def redirect_response(uri, status=nil)
      status_code = Rack::Utils.status_code(status || :see_other)
      response = Rack::Response.new([], status_code)
      response.redirect(uri.to_s, status_code) if uri
      response
    end

    def error_response(status)
      if @error_filename
        send_file_response(@error_filename, status)
      else
        Rack::Response.new([], Rack::Utils.status_code(status))
      end
    end

    def send_file_response(filename, status, send_body=true)
      headers = {
        'Content-Type' => Rack::Mime.mime_type(filename.extname, 'application/octet-stream'),
        'Content-Length' => filename.size.to_s,
        'Last-Modified' => filename.mtime.httpdate,
      }
      body = []
      if send_body
        if @use_x_sendfile
          headers['X-Sendfile'] = filename.to_s
        else
          body = filename.open('rb')
        end
      end
      Rack::Response.new(body, Rack::Utils.status_code(status), headers)
    end

  end

end