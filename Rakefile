#!/usr/bin/rake
require 'yaml'
require 'json'
require 'net/http'
require 'uri'
require 'plist'
require 'English'

namespace :repos do
  REPOS = %i[StencilSwiftKit SwiftGenKit SwiftGen templates].freeze
  desc 'Bootstrap this repository for development'
  task :bootstrap do
    REPOS.each do |repository|
      next if Dir.exist? repository.to_s

      sh "git clone git@github.com:SwiftGen/#{repository}.git --recursive"
      Dir.chdir(repository.to_s) do
        sh 'git submodule update --init --recursive'
      end
    end
  end

  def each_repo
    REPOS.each do |repo|
      Dir.chdir(repo.to_s) do
        Utils.print_header "=== #{repo} ==="
        yield
      end
    end
  end

  desc 'Print status of each repo'
  task :status do
    each_repo { puts `git status` }
  end

  desc 'git pull each repo'
  task :pull do
    each_repo { puts `git pull` }
  end

  desc 'git checkout master each repo'
  task :master do
    each_repo { puts `git checkout master` }
  end
end

namespace :submodules do
  def submodules(cmd)
    %i[SwiftGenKit SwiftGen].each do |repository|
      Utils.print_header repository.to_s
      Dir.chdir(repository.to_s) do
        sh(cmd)
      end
    end
  end

  desc 'Synchronize all submodules to make them point to master'
  task :master do
    submodules("git submodule foreach 'git checkout master && git pull'")
  end

  desc 'Show status for submodules of each repo'
  task :status do
    Utils.print_header "Current 'templates' commit"
    Dir.chdir('templates') { sh 'git describe --all && git describe --always' }
    submodules('git submodule status')
  end
end

## [ Release a new version ] ##################################################

namespace :release do
  desc 'Create a new release on GitHub, CocoaPods and Homebrew'
  task :new => [:check_versions, 'swiftgen:tests', :github, :cocoapods, :homebrew]

  desc 'Check if all versions from the podspecs and CHANGELOG match'
  task :check_versions do
    results = []

    # Check if bundler is installed first, as we'll need it for the cocoapods task (and we prefer to fail early)
    `which bundler`
    results << Utils.table_result(
      $CHILD_STATUS.success?,
      'Bundler installed',
      'Please install bundler using `gem install bundler` and run `bundle install` first.'
    )

    # Extract version from SwiftGen.podspec
    version = Utils.podspec_version('SwiftGen')
    Utils.table_info('SwiftGen.podspec', version)

    # Check SwiftGenKit & StencilSwiftKit versions too
    check_dep_versions = lambda do |pod|
      lock_version = Utils.podfile_lock_version(pod)
      pod_version = Utils.podspec_version(pod)
      results << Utils.table_result(
        lock_version == pod_version,
        "#{pod.ljust(Utils::COLUMN_WIDTH - 10)} (#{pod_version})",
        "Please update #{pod} to latest version in your Podfile"
      )
    end
    check_dep_versions.call('SwiftGenKit')
    check_dep_versions.call('StencilSwiftKit')

    # Check if version matches the Info.plist
    results << Utils.table_result(
      version == Utils.plist_version,
      'Info.plist version matches',
      'Please update the version numbers in the Info.plist file'
    )

    # Check if submodule is aligned
    submodule_aligned = Dir.chdir('SwiftGen/Resources') do
      sh 'git fetch origin >/dev/null'
      `git rev-parse origin/master`.chomp == `git rev-parse HEAD`.chomp
    end
    results << Utils.table_result(
      submodule_aligned,
      'Submodule on origin/master',
      'Please align the submodule to master'
    )

    # Check if entry present in CHANGELOG
    changelog_entry = system("grep -q '^## #{Regexp.quote(version)}$' SwiftGen/CHANGELOG.md")
    results << Utils.table_result(
      changelog_entry,
      'CHANGELOG, Entry added',
      "Please add an entry for #{version} in CHANGELOG.md"
    )

    changelog_master = system("grep -qi '^## Master' SwiftGen/CHANGELOG.md")
    results << Utils.table_result(
      !changelog_master,
      'CHANGELOG, No master',
      'Please remove entry for master in CHANGELOG'
    )

    exit 1 unless results.all?

    print "Release version #{version} [Y/n]? "
    exit 2 unless STDIN.gets.chomp == 'Y'
  end

  desc 'Create a zip containing all the prebuilt binaries'
  task :zip => ['swiftgen:clean', 'swiftgen:install'] do
    `cp SwiftGen/LICENSE SwiftGen/README.md SwiftGen/CHANGELOG.md SwiftGen/build/swiftgen`
    `cd SwiftGen/build/swiftgen; zip -r ../swiftgen-#{Utils.podspec_version}.zip .`
  end

  def post(url, content_type)
    uri = URI.parse(url)
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = content_type unless content_type.nil?
    yield req if block_given?
    req.basic_auth 'AliSoftware', File.read('.apitoken').chomp

    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) do |http|
      http.request(req)
    end
    unless response.code == '201'
      Utils.print_error "Error: #{response.code} - #{response.message}"
      puts response.body
      exit 3
    end
    JSON.parse(response.body)
  end

  desc 'Upload the zipped binaries to a new GitHub release'
  task :github => :zip do
    v = Utils.podspec_version

    changelog = `sed -n /'^## #{v}$'/,/'^## '/p SwiftGen/CHANGELOG.md`.gsub(/^## .*$/, '').strip
    Utils.print_header "Releasing version #{v} on GitHub"
    puts changelog

    json = post('https://api.github.com/repos/SwiftGen/SwiftGen/releases', 'application/json') do |req|
      req.body = { :tag_name => v, :name => v, :body => changelog, :draft => false, :prerelease => false }.to_json
    end

    upload_url = json['upload_url'].gsub(/\{.*\}/, "?name=swiftgen-#{v}.zip")
    zipfile = "SwiftGen/build/swiftgen-#{v}.zip"
    zipsize = File.size(zipfile)

    Utils.print_header "Uploading ZIP (#{zipsize} bytes)"
    post(upload_url, 'application/zip') do |req|
      req.body_stream = File.open(zipfile, 'rb')
      req.add_field('Content-Length', zipsize)
      req.add_field('Content-Transfer-Encoding', 'binary')
    end
  end

  desc 'pod trunk push SwiftGen to CocoaPods'
  task :cocoapods do
    Utils.print_header 'Pushing pod to CocoaPods Trunk'
    Dir.chdir('SwiftGen') do
      sh 'bundle exec pod trunk push SwiftGen.podspec'
    end
  end

  desc 'Release a new version on Homebrew and prepare a PR'
  task :homebrew do
    Utils.print_header 'Updating Homebrew Formula'
    tag = Utils.podspec_version
    revision = Dir.chdir('SwiftGen') do
      sh 'git pull --tags'
      `git rev-list -1 #{tag}`.chomp
    end
    formulas_dir = Bundler.with_clean_env { `brew --repository homebrew/core`.chomp }
    Dir.chdir(formulas_dir) do
      sh 'git checkout master'
      sh 'git pull'
      sh "git checkout -b swiftgen-#{tag} origin/master"

      formula_file = "#{formulas_dir}/Formula/swiftgen.rb"
      formula = File.read(formula_file)

      new_formula = formula
                    .gsub(/:tag => ".*"/, %(:tag => "#{tag}"))
                    .gsub(/:revision => ".*"/, %(:revision => "#{revision}"))
      File.write(formula_file, new_formula)
      Utils.print_header 'Checking Homebrew formula...'
      Bundler.with_clean_env do
        sh 'brew audit --strict --online swiftgen'
        sh 'brew upgrade swiftgen'
        sh 'brew test swiftgen'
      end

      Utils.print_header 'Pushing to Homebrew'
      sh "git add #{formula_file}"
      sh "git commit -m 'swiftgen #{tag}'"
      sh "git push -u AliSoftware swiftgen-#{tag}"
      sh "open 'https://github.com/Homebrew/homebrew-core/compare/master...AliSoftware:swiftgen-#{tag}?expand=1'"
    end
  end
end

task :default => 'release:new'
