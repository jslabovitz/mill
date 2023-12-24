module Mill

  module Commands

    class Snapshot < Command

      def run(args)
        super
        @site.output_dir.chdir do
          run_command(%w[git init]) unless Path.new('.git').exist?
          run_command(%w[git add .])
          run_command(%w[git commit -a -m Update.])
        end
      end

    end

  end

end