namespace :sync do
  REPOSITORIES = [:StencilSwiftKit, :SwiftGenKit, :SwiftGen, :templates]

  desc 'Synchronize all files across repositories'
  task :all_files => [:rakelib, :gitignore, :license]

  task :gems do |task|
    REPOSITORIES.each do |repository|
      FileUtils.cp('common/Gemfile', "#{repository}/")
      FileUtils.cp('common/Gemfile.lock', "#{repository}/")
    end
  end

  task :rakelib => :gems do |task|
    REPOSITORIES.each do |repository|
      FileUtils.rm_rf("#{repository}/rakelib")
      FileUtils.cp_r('common/rakelib', "#{repository}/")
    end
  end

  task :gitignore do |task|
    REPOSITORIES.each do |repository|
      FileUtils.cp('common/gitignore', "#{repository}/.gitignore")
    end
  end

  task :license do |task|
    REPOSITORIES.each do |repository|
      FileUtils.cp('LICENSE', "#{repository}/")
    end
  end
end
