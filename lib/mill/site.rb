module Mill

  class Site

    attr_accessor :content_dir
    attr_accessor :site_dir

    def initialize(params={})
      @content_dir = Path.new('content')
      @site_dir = Path.new('site')
      @server_port = 8000
      @pipelines = {
        '*.html' => [
          Filters::ReadFile,
          Filters::ParseHTML,
          Filters::DecorateHTML,
          Filters::AddExternalLinkTargets,
          Filters::AddImageSizes,
          Filters::WriteFile
        ],
        '*.{md,mdown,markdown}' => [
          Filters::ReadFile,
          Filters::ParseMarkdown,
          Filters::MarkdownToHTML
        ],
        '*' => [
          Filters::CopyFile,
        ],
      }
      params.each { |k, v| send("#{k}=", v) }
    end

    def clean
      log.info "cleaning site"
      @site_dir.rmtree
    end

    def build(*files)
      log.info "building site"
      if files.empty?
        files = @content_dir.glob('**/**/*')
      else
        files = files.map { |p| Path.new(p) }
      end
      files.reject { |f| f.hidden? || f.directory? }.each do |file|
        log.debug(1) { "processing #{file.to_s.inspect}" }
        dest_file = @site_dir / file.relative_path_from(@content_dir)
        resource = Resource.new(src_file: file, dest_file: dest_file, site: self)
        log.debug(2) { "before: #{resource.inspect}" }
        process(resource)
        log.debug(2) { "after : #{resource.inspect}" }
      end
    end

    def process(resource)
      loop do
        pattern, pipeline = @pipelines.find { |pat, pipeline| resource.dest_file.fnmatch?(pat, File::FNM_CASEFOLD | File::FNM_EXTGLOB) }
        break unless pattern
        old_dest_file = resource.dest_file.dup
        pipeline.flatten.each { |filter| filter.new.process(resource) }
        break if resource.dest_file == old_dest_file
      end
    end

    def server
      server = WEBrick::HTTPServer.new(:Port => @server_port, :DocumentRoot => @site_dir)
      trap('INT') { server.shutdown }
      server.start
    end

    def validate
      #FIXME
    end

  end

end