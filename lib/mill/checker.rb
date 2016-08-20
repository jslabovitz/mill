module Mill

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

    SchemasDir = Path.new(__FILE__).dirname / 'schemas'
    Schemas = {
      'feed' => SchemasDir / 'atom.xsd',
      'urlset' => SchemasDir / 'sitemap.xsd',
    }

    def initialize(root)
      @root = Path.new(root)
      @schemas = {}
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
      return if (!uri.scheme.nil? && uri.scheme != 'http') || !uri.host.to_s.empty? || @visited[uri]
      # ;;warn ('  ' * level) + "CHECKING: #{uri}"
      @visited[uri] = true
      request = make_request(uri)
      response = @server.handle_request(request)
      # ;;pp(request: request, response: response)
      links = []
      case response.status
      when 200...300
        file_path = Path.new(response.headers['X-Sendfile'])
        @files.delete(file_path.relative_path_from(@root))
        case (type = response.headers['Content-Type'])
        when 'text/html'
          links = check_html(file_path)
        when 'text/css'
          links = check_css(file_path)
        when 'application/xml'
          links = check_xml(file_path)
        when %r{^(image|video|audio|text|application)/}
          # ignore
        else
          ;;warn ('  ' * level) + "SKIPPING: #{uri} (#{type})"
        end
      when 300...400
        redirect_uri = Addressable::URI.parse(response.headers['Location'])
        links << uri + redirect_uri
      when 404
        raise "URI not found: #{uri}" unless uri.path == '/favicon.ico'
      else
        raise "Bad status: #{response.inspect}"
      end
      links.each { |link| check(uri + link, level + 1) }
    end

    def check_html(html_file)
      html = html_file.read
      tidy = TidyFFI::Tidy.new(html, char_encoding: 'UTF8')
      unless (errors = tidy_errors(tidy)).empty?
        warn "#{html_file} has invalid HTML"
        errors.each do |error|
          warn "\t#{error[:msg]}"
        end
        raise HTMLError
      end
      doc = parse_html(html)
      find_link_elements(doc).map(&:value)
    end

    def tidy_errors(tidy)
      return [] unless tidy.errors
      tidy.errors.split(/\n/).map { |str|
        str =~ /^line (\d+) column (\d+) - (.*?): (.*)$/ or raise "Can't parse error: #{str.inspect}"
        {
          msg: str,
          line: $1.to_i,
          column: $2.to_i,
          type: $3.downcase.to_sym,
          error: $4.strip,
        }
      }.reject { |e|
        IgnoreErrors.include?(e[:error])
      }
    end

    def check_xml(xml_file)
      xml_doc = Nokogiri::XML::Document.parse(xml_file.read) { |config| config.strict }
      unless xml_doc.errors.empty?
        show_xml_errors(xml_doc.errors)
        raise 'XML parsing failed'
      end
      root_name = xml_doc.root.name
      schema_file = Schemas[root_name] or raise "Can't find schema for XML root element <#{root_name}>"
      unless (schema = @schemas[schema_file])
        ;;warn "loading schema for <#{root_name}> element"
        schema = @schemas[schema_file] = Nokogiri::XML::Schema((SchemasDir / schema_file).open) { |c| c.strict.nonet }
      end
      validation_errors = schema.validate(xml_doc)
      unless validation_errors.empty?
        show_xml_errors(validation_errors)
        raise 'XML validation failed'
      end
      find_link_elements(xml_doc).map(&:value)
    end

    def show_xml_errors(errors)
      errors.each do |error|
        warn "#{error} [line #{error.line}, column #{error.column}]"
      end
    end

    def check_css(css_file)
      links = []
      css_file.read.gsub(/\burl\(\s*["'](.*?)["']\s*\)/) { links << $1 }
      links
    end

    def report
      unless @files.empty?
        puts "\t" + "unreferenced files:"
        @files.sort.each do |path|
          puts "\t\t" + path.to_s
        end
      end
    end

    def make_request(uri)
      Rack::Request.new(
        'GATEWAY_INTERFACE' => 'CGI/1.1',
        'REQUEST_METHOD' => 'GET',
        'rack.url_scheme' => 'http',
        'PATH_INFO' => uri.path,
      )
    end

  end

end