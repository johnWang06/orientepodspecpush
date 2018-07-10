require "orientepodspecpush/version"
require 'colorize'
require 'trollop'

module Orientepodspecpush
  class PodPush

    def specfile
      Dir["*.podspec"].first
    end

    def shouldUseBundleExec
      File.exist?('Gemfile')
    end

    def ensureSpecfile
      podspecFile = specfile

      puts "No spec file found".red unless podspecFile != nil
      exit unless podspecFile != nil
    end

    def ensureGitClean
      if `git status --porcelain`.length != 0
        puts "Repo is not clean; will not push new version".red
        exit
      end

      cmd = []
      cmd << ['bundle exec'] if shouldUseBundleExec
      cmd << ['pod cache clean --all']
      system cmd.join(' ')
    end

    def makeLintCmd(opts)
      lintCmd = []
      lintCmd << ['bundle exec'] if shouldUseBundleExec
      lintCmd << ["pod spec lint"]

      # Build sources
      sources = ["https://github.com/CocoaPods/Specs.git"]
      sources << opts[:sources] unless opts[:sources] == nil
      sourcesArg = "--sources=" + sources.join(",")

      # Build lintCmd
      lintCmd << specfile
      lintCmd << sourcesArg
      lintCmd << ["--private"] unless opts[:private] == false

      # finalize
      lintCmd.join(' ')
    end

    def makePushCmd(opts)
      cmd = []
      cmd << ['bundle exec'] if shouldUseBundleExec
      cmd << ["pod repo push #{opts[:specRepo]} #{specfile} --allow-warnings"]

      cmd.join(' ')
    end

    def updateVersion
      puts "Please enter new version of the pod so we can tag, lint and push it! (e.g. 1.2.0)".blue
      @podVersion = gets.chomp.downcase

      puts "Please enter new a brief message to put in the git tag describing what's changed".blue
      @podVersionMessage = gets.chomp.downcase

      system "git tag -a #{@podVersion} -m '#{@podVersionMessage}'"
      system "git push --tags"

      contents = File.read(specfile)
      oldVersion = Regexp.new('[0-9.]{2,6}').match(Regexp.new('(s.version)\s*=.*\n').match(contents).to_s).to_s
      File.write(specfile, contents.sub!(oldVersion, @podVersion))
    end

    def rollbackTag
      puts "Rolling back git tags".green
      system "git tag -d #{@podVersion}"
      system "git push -d origin #{@podVersion}"
      exit
    end

    def executeLint(withWarnings)
      cmd = [@lintCmd]
      cmd << "--allow-warnings" unless withWarnings == false

      command = cmd.join(' ')

      puts "Executing: #{command}".green
      success = system command

      if success == false && withWarnings == false
        # Try again?
        puts "Linting failed, try again by allowing warnings? [Y/n]".blue
        gets.chomp.downcase == "y" ? executeLint(true) : rollbackTag
      elsif success == false && withWarnings == true
        puts "Even with warnings, something is wrong. Look for any errors".red
        rollbackTag
      end
    end

    def executePush
      puts "Executing: #{@pushCmd}".green
      success = system @pushCmd

      if success == false
        puts "Push failed, see errors.".red
        rollbackTag
      end
    end

    def commitThisRepo
      puts "Congrats! The pod has been linted and successfully push to the spec repo! All that is left is to commit the podspec here!".green

      puts "Could not commit files, consider finishing by hand by performing a git commit and push. Your spec repo should be up to date".red unless system('git commit -am "[Versioning] Updating podspec"') == true
      puts "Could not push to server, consider finishing by hand by performing a git push. Your spec repo should be up to date".red unless system('git push origin master')
    end

    def push
      opts = Trollop::options do
        opt :specRepo, "Name of the repo to push to. See pod repo list for available repos", :type => :string
        opt :workspace, "Path to cocoapod workspace", :type => :string
        opt :sources, "Comma delimited list of private repo sources to consider when linting private repo. Master is included by default so private repos can source master", :type => :string
        opt :private, "If set, assume the cocoapod is private and skip public checks"
      end
      # Need these two
      Trollop::die :specRepo, "Spec Repo must be provided" if opts[:specRepo] == nil
      Trollop::die :workspace, "Workspace path must be provided" if opts[:workspace] == nil

      Dir.chdir(opts[:workspace]) do
        # Check
        ensureGitClean
        ensureSpecfile

        # User input
        updateVersion

        # Cmds
        @lintCmd = makeLintCmd(opts)
        @pushCmd = makePushCmd(opts)

        # execute
        executeLint(false)
        executePush

        # Tidy up this repo!!
        commitThisRepo
      end
    end
  end
end
