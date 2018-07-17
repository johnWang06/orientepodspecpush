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

    def package(opts)
      puts "start package".green
      cmd = []
      cmd << ['bundle exec'] if shouldUseBundleExec
      podPackage = "pod package #{specfile}"
      cmd << [podPackage]
      cmd << opts[:package] unless opts[:package] == nil
      
      system cmd.join(' ')

      puts "finish package".green
      # system "git add ."
      # system "git commit -m 'upload framework'"
      # system "git push origin master"

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
      lintCmd << "pod spec lint"
 
      # Build sources
      # sources = ["https://github.com/CocoaPods/Specs.git"]
      # sources << opts[:sources] unless opts[:sources] == nil
      # unless opts[:lint] == nil
      #   sources << opts[:lint]
      # end

      
      # sourcesArg = "--sources=" + sources.join(",")

     
     

      # Build lintCmd
      lintCmd << specfile
      # lintCmd << sourcesArg
      lintCmd << opts[:sources] unless opts[:sources] == nil
      lintCmd <<  ["#{opts[:lint]}"]
      lintCmd << ["--private"] unless opts[:private] == false

      # finalize
      lintCmd.join(' ')
    end

    def makePushCmd(opts)
      cmd = []
      cmd << ['bundle exec'] if shouldUseBundleExec
      podRepoPush = "pod repo push #{opts[:specRepo]} #{specfile}"
      cmd << [podRepoPush]
      cmd << opts[:push] unless opts[:push] == nil      

      cmd.join(' ')
    end

    def updateVersion
#      puts "Please enter new version of the pod so we can tag, lint and push it! (e.g. 1.2.0)".blue
#      @podVersion = gets.chomp.downcase
#
#      puts "Please enter new a brief message to put in the git tag describing what's changed".blue
#      @podVersionMessage = gets.chomp.downcase

#      system "git add ."
#      system "git commit -m 'upload framework'"
#
# @podVersion = opts[:tag]
# @podVersionMessage = opts[:tagCommitMsg]
      if @podVersionMessage == nil
        system "git tag -a #{@podVersion} -m 'add new tag'"
      else
        system "git tag -a #{@podVersion} -m '#{@podVersionMessage}'"
      end
      # system "git tag -a #{@podVersion} -m '#{@podVersionMessage}'"
      system "git push --tags"

      contents = File.read(specfile)
      oldVersion = Regexp.new('[0-9.]{2,8}').match(Regexp.new('(s.version)\s*=.*\n').match(contents).to_s).to_s
      File.write(specfile, contents.sub!(oldVersion, @podVersion))
      
#      cmd = []
#      cmd << ['bundle exec'] if shouldUseBundleExec
#      cmd << ["pod package #{specfile} --force"]
#
#      system cmd.join(' ')
#      system "git add ."
#      system "git commit -m 'upload framework'"
#      system "git push origin master"

      
#      system "git tag -a #{@podVersion} -m '#{@podVersionMessage}'"
#      system "git push --tags"
    end

    def rollbackTag
      puts "Rolling back git tags".green

      system "git checkout ."
      system "git tag -d #{@podVersion}"
      system "git push -d origin #{@podVersion}"
      exit
    end

    def executeLint(withWarnings,opts)
      cmd = [@lintCmd]
      # cmd << "--allow-warnings" unless withWarnings == false

      command = cmd.join('')

      puts "Executing: #{command}".green
      success = system command

      if success == false && withWarnings == false
        # Try again?
        puts "Linting failed, try again by allowing warnings? [Y/n]".blue
        gets.chomp.downcase == "y" ? executeLint(true,opts) : rollbackTag
      elsif success == false && withWarnings == true
        puts "Even with warnings, something is wrong. Look for any errors".red
        rollbackTag
      else
        unless opts[:noPackage] == true
          package(opts)
        end
      end
    end

    def executePush(opts)
      puts "Executing: #{@pushCmd}".green
      success = system @pushCmd

      if success == false
        puts "Push failed, see errors.".red
        rollbackTag
      end
    end

    def commitThisRepo
      system "git add ."
      puts "Congrats! The pod has been linted and successfully push to the spec repo! All that is left is to commit the podspec here!".green

      puts "Could not commit files, consider finishing by hand by performing a git commit and push. Your spec repo should be up to date".red unless system('git commit -am "[Versioning] Updating podspec"') == true
      puts "Could not push to server, consider finishing by hand by performing a git push. Your spec repo should be up to date".red unless system('git push origin master')
    end

    def push
      opts = Trollop::options do
        version "#{Orientepodspecpush::VERSION}"
        opt :specRepo, "Name of the repo to push to. See pod repo list for available repos", :type => :string
        opt :workspace, "Path to cocoapod workspace", :type => :string
        opt :sources, "Comma delimited list of private repo sources to consider when linting private repo. Master is included by default so private repos can source master", :type => :string
        opt :private, "If set, assume the cocoapod is private and skip public checks"
        opt :tag, "tag of the repo push to", :type => :string
        opt :tagCommitMsg, "commit message of this tag", :type => :string
        opt :lint, "pod spec lint 情况下所需要的参数，需要用引号括起来，例如'--allow-warnings --sources=some source address'",:type => :string
        opt :package, "pod package  情况下所需要的参数，需要用引号括起来，例如'--force --no-mangle'",:type => :string
        opt :push, "pod repo push 情况下所需要的参数，需要用引号括起来，例如'--verbose --use-libraries'",:type => :string
        opt :noPackage, "If set, no need to package"
      end

      puts "lint:#{opts[:lint]}"
      puts "package:#{opts[:package]}"
      puts "push:#{opts[:push]}"
      puts "noPackage:#{opts[:noPackage]}"
      puts "tag:#{opts[:tag]}"
      # Need these two
      Trollop::die :specRepo, "Spec Repo must be provided" if opts[:specRepo] == nil
      Trollop::die :workspace, "Workspace path must be provided" if opts[:workspace] == nil
      Trollop::die :tag, "tag must be provided" if opts[:tag] == nil

      Dir.chdir(opts[:workspace]) do
        # Check
        ensureGitClean
        ensureSpecfile
#        packageCode

        # User input
        @podVersion = opts[:tag]
        @podVersionMessage = opts[:tagCommitMsg]
        updateVersion

        # Cmds
        @lintCmd = makeLintCmd(opts)
        @pushCmd = makePushCmd(opts)

        # execute
        executeLint(true,opts)
        executePush(opts)

        # Tidy up this repo!!
        commitThisRepo
      end
    end
  end
end
