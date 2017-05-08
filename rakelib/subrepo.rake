namespace :swiftgen do
  desc 'Run tests on SwiftGen repo'
  task :tests do
    Dir.chdir("SwiftGen") do
      sh "rake xcode:tests"
    end
  end

  desc 'Clean the build on SwiftGen repo'
  task :clean do
    Dir.chdir("SwiftGen") do
      sh "rake cli:clean"
    end
  end

  desc 'Run the install task SwiftGen repo'
  task :install do
    Dir.chdir("SwiftGen") do
      sh "rake cli:install"
    end
  end
end
