module Mill

  module Commands

    class Upload < Command

      def run(args)
        super
        raise "site_rsync not defined" unless @site.site_rsync
        options = %w[
          --progress
          --verbose
          --archive
          --exclude=.git
          --delete-after
        ]
        run_command('rsync', *options, @site.output_dir, @site.site_rsync)
      end

    end

  end

end