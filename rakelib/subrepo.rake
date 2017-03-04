namespace :swiftgen do
  task :tests do
    Dir.chdir("SwiftGen") do
      sh "rake xcode:tests"
    end
  end

  task :clean do
    Dir.chdir("SwiftGen") do
      sh "rake cli:clean"
    end
  end

  task :install do
    Dir.chdir("SwiftGen") do
      sh "rake cli:install"
    end
  end
end
