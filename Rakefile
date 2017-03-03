#!/usr/bin/rake
require 'yaml'
require 'json'
require 'net/http'
require 'uri'
require 'plist'

desc 'Bootstrap this repository for development'
task :bootstrap do
  [:StencilSwiftKit, :SwiftGenKit, :SwiftGen, :templates].each do |repository|
    next if Dir.exists? "#{repository}"

    sh "git clone git@github.com:SwiftGen/#{repository}.git --recursive"
    Dir.chdir("#{repository}") do
      sh "git submodule update --init --recursive"
    end
  end
end

## [ Release a new version ] ##################################################

namespace :release do
  desc 'Create a new release on GitHub, CocoaPods and Homebrew'
  task :new => [:check_versions, 'swiftgen:tests', :github, :cocoapods, :homebrew]

  def podspec_version(file = 'SwiftGen')
    JSON.parse(`bundle exec pod ipc spec SwiftGen/#{file}.podspec`)["version"]
  end

  def plist_version
    Plist::parse_xml('SwiftGen/Sources/Info.plist')['CFBundleVersion']
  end

  def log_result(result, label, error_msg)
    if result
      puts "#{label.ljust(30)} \u{2705}"
    else
      puts "#{label.ljust(30)} \u{274C}  - #{error_msg}"
    end
    result
  end

  desc 'Check if all versions from the podspecs and CHANGELOG match'
  task :check_versions do
    results = []

    # Check if bundler is installed first, as we'll need it for the cocoapods task (and we prefer to fail early)
    `which bundler`
    results << log_result( $?.success?, 'Bundler installed', 'Please install bundler using `gem install bundler` and run `bundle install` first.')

    # Extract version from SwiftGen.podspec
    version = podspec_version
    puts "#{'SwiftGen.podspec'.ljust(30)} \u{1F449}  #{version}"

    # Check if version matches the Info.plist
    results << log_result(version == plist_version, "Info.plist version matches", "Please update the version numbers in the Info.plist file")

    # Check if entry present in CHANGELOG
    changelog_entry = system(%Q{grep -q '^## #{Regexp.quote(version)}$' SwiftGen/CHANGELOG.md})
    results << log_result(changelog_entry, "CHANGELOG, Entry added", "Please add an entry for #{version} in CHANGELOG.md")

    changelog_master = system(%q{grep -qi '^## Master' SwiftGen/CHANGELOG.md})
    results << log_result(!changelog_master, "CHANGELOG, No master", 'Please remove entry for master in CHANGELOG')

    exit 1 unless results.all?

    print "Release version #{version} [Y/n]? "
    exit 2 unless (STDIN.gets.chomp == 'Y')
  end

  desc 'Create a zip containing all the prebuilt binaries'
  task :zip => ['swiftgen:clean', 'swiftgen:install'] do
    `cp SwiftGen/LICENSE SwiftGen/README.md SwiftGen/CHANGELOG.md SwiftGen/build/swiftgen`
    `cd SwiftGen/build/swiftgen; zip -r ../swiftgen-#{podspec_version}.zip .`
  end

  def post(url, content_type)
    uri = URI.parse(url)
    req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' => content_type})
    yield req if block_given?
    req.basic_auth 'AliSoftware', File.read('.apitoken').chomp

    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) do |http|
      http.request(req)
    end
    unless response.code == '201'
      puts "Error: #{response.code} - #{response.message}"
      puts response.body
      exit 3
    end
    JSON.parse(response.body)
  end

  desc 'Upload the zipped binaries to a new GitHub release'
  task :github => :zip do
    v = podspec_version

    changelog = `sed -n /'^## #{v}$'/,/'^## '/p CHANGELOG.md`.gsub(/^## .*$/,'').strip
    print_info "Releasing version #{v} on GitHub"
    puts changelog

    json = post('https://api.github.com/repos/SwiftGen/SwiftGen/releases', 'application/json') do |req|
      req.body = { :tag_name => v, :name => v, :body => changelog, :draft => false, :prerelease => false }.to_json
    end

    upload_url = json['upload_url'].gsub(/\{.*\}/,"?name=swiftgen-#{v}.zip")
    zipfile = "build/swiftgen-#{v}.zip"
    zipsize = File.size(zipfile)

    print_info "Uploading ZIP (#{zipsize} bytes)"
    post(upload_url, 'application/zip') do |req|
      req.body_stream = File.open(zipfile, 'rb')
      req.add_field('Content-Length', zipsize)
      req.add_field('Content-Transfer-Encoding', 'binary')
    end
  end

  desc 'pod trunk push SwiftGen to CocoaPods'
  task :cocoapods do
    print_info "Pushing pod to CocoaPods Trunk"
    sh 'bundle exec pod trunk push SwiftGen.podspec'
  end

  desc 'Release a new version on Homebrew and prepare a PR'
  task :homebrew do
    print_info "Updating Homebrew Formula"
    tag = podspec_version
    formulas_dir = `brew --repository homebrew/core`.chomp
    Dir.chdir(formulas_dir) do
      sh 'git checkout master'
      sh 'git pull'
      sh "git checkout -b swiftgen-#{tag} origin/master"

      formula_file = "#{formulas_dir}/Formula/swiftgen.rb"
      formula = File.read(formula_file)
      new_formula = formula.gsub(%r(url "(.*)", :tag => ".*"), %Q(url "\\1", :tag => "#{tag}"))
      File.write(formula_file, new_formula)

      print_info "Checking Homebrew formula..."
      sh 'brew audit --strict --online swiftgen'
      sh 'brew upgrade swiftgen'
      sh 'brew test swiftgen'

      print_info "Pushing to Homebrew"
      sh "git add #{formula_file}"
      sh "git commit -m 'swiftgen #{tag}'"
      sh "git push -u AliSoftware swiftgen-#{tag}"
      sh "open 'https://github.com/Homebrew/homebrew-core/compare/master...AliSoftware:swiftgen-#{tag}?expand=1'"
    end
  end
end

task :default => "release:new"

## [ SwiftGen subtasks ] ##############################################################

namespace :swiftgen do
  task :tests do
    Dir.chdir("SwiftGen") do
      sh "rake tests"
    end
  end

  task :clean do
    Dir.chdir("SwiftGen") do
      sh "rake clean"
    end
  end

  task :install do
    Dir.chdir("SwiftGen") do
      sh "rake install"
    end
  end
end
