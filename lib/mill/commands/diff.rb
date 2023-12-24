module Mill

  module Commands

    class Diff < Command

      def run(args)
        super
        @site.output_dir.chdir do
          run_command(%w[git diff])
        end
      end

    end

  end

end