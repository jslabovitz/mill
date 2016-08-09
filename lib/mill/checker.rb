class Mill

  class Checker

    include HTMLHelpers

    IgnoreErrors = %Q{
      <table> lacks "summary" attribute
      <img> lacks "alt" attribute
      <form> proprietary attribute "novalidate"
      <input> attribute "type" has invalid value "email"
      <input> attribute "tabindex" has invalid value "-1"
      <input> proprietary attribute "border"
      trimming empty <p>
      <iframe> proprietary attribute "allowfullscreen"
    }.split(/\n/).map(&:strip)

    def initialize(root)
      @root = Path.new(root)
      find_files
      @visited = {}
      @server = Server.new(root: @root, use_x_sendfile: true)
    end

    def find_files
      @files = []
      @root.find do |path|
        if path.file? && path.extname != '.redirect'
          @files << path.relative_path_from(@root)
        end
      end
    end

    def check(uri, level=0)
      uri = Addressable::URI.parse(uri)
      return if !uri.host.to_s.empty? || @visited[uri]
      # ;;warn ('  ' * level) + "CHECKING: #{uri}"
      @visited[uri] = true
      request = make_request(uri)
      response = @server.handle_request(request)
      # ;;pp(request: request, response: response)
      case response.status
      when 200...300
        file_path = Path.new(response.headers['X-Sendfile'])
        @files.delete(file_path.relative_path_from(@root))
        case (type = response.headers['Content-Type'])
        when 'text/html'
          html = file_path.read
          tidy_html(html, label: file_path) or raise "Invalid HTML"
          html_links(html).each do |link|
            check(uri + link, level + 1)
          end
        when 'text/css'
          css_links(file_path.read).each do |link|
            check(uri + link, level + 1)
          end
        when 'application/xml'
          #FIXME -- parse XML
        else
          # ;;warn ('  ' * level) + "SKIPPING: #{type}"
        end
      when 300...400
        redirect_uri = Addressable::URI.parse(response.headers['Location'])
        check(uri + redirect_uri, level + 1)
      when 404
        raise "URI not found: #{uri}" unless uri.path == '/favicon.ico'
      else
        raise "Bad status: #{response.inspect}"
      end
    end

    def html_links(html)
      html_doc = parse_html(html)
      LinkElementsXPaths.map { |x| html_doc.xpath(x).map(&:value) }.flatten
    end

    def css_links(css)
      links = []
      css.gsub(/\burl\(\s*'(.*?)'\s*\)/) { links << $1 }
      links
    end

    def report
      unless @files.empty?
        puts; puts "ORPHAN FILES:"
        @files.sort.each do |path|
          puts "\t" + path.to_s
        end
      end
    end

    def make_request(uri)
      Rack::Request.new(
        'GATEWAY_INTERFACE' => 'CGI/1.1',
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => uri.path,
        'SERVER_NAME' => uri.host,
        'SERVER_PORT' => uri.port,
        'rack.url_scheme' => uri.scheme,
      )
    end

    def tidy_html(html, label=nil)
      html_str = html.to_s
      tidy = TidyFFI::Tidy.new(html_str, char_encoding: 'UTF8')
      return true unless tidy.errors
      errors = tidy.errors.split(/\n/).map do |error_str|
        error_str =~ /^line (\d+) column (\d+) - (.*?): (.*)$/ or raise "Can't parse error: #{error_str}"
        {
          msg: error_str,
          line: $1.to_i - 1,
          column: $2.to_i - 1,
          type: $3.downcase.to_sym,
          error: $4.strip,
        }
      end.reject do |error|
        IgnoreErrors.include?(error[:error])
      end
      return true if errors.empty?
      fatal_error = false
      warn (label ? "#{label}: " : '') + "invalid HTML:"
      html_lines = html_str.split(/\n/)
      errors.each do |error|
        warn "\t#{error[:msg]}:"
        html_lines.each_with_index do |html_line, i|
          if i >= [0, error[:line] - 2].max && i <= [error[:line] + 2, html_lines.length].min
            if i == error[:line]
              output = [
                error[:column] > 0 ? (html_line[0 .. error[:column] - 1]) : '',
                Term::ANSIColor.negative,
                html_line[error[:column]],
                Term::ANSIColor.clear,
                html_line[error[:column] + 1 .. -1],
              ].join
            else
              output = html_line
            end
            warn "\t\t%3s: %s" % [i + 1, output]
          end
        end
        fatal_error ||= (error[:type] == :error)
      end
      !fatal_error
    end

  end

end