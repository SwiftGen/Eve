namespace :sync do
  REPOSITORIES = %i[StencilSwiftKit SwiftGenKit SwiftGen templates].freeze

  desc 'Synchronize all files across repositories'
  task :all_files => %i[rakelib gitignore rubocop license]

  task :gems do |_task|
    REPOSITORIES.each do |repository|
      FileUtils.cp('common/Gemfile', "#{repository}/")
      FileUtils.cp('common/Gemfile.lock', "#{repository}/")
    end
  end

  task :rakelib => :gems do |_task|
    REPOSITORIES.each do |repository|
      FileUtils.rm_rf("#{repository}/rakelib")
      FileUtils.cp_r('common/rakelib', "#{repository}/")
    end
  end

  task :gitignore do |_task|
    REPOSITORIES.each do |repository|
      FileUtils.cp('common/gitignore', "#{repository}/.gitignore")
    end
  end

  task :rubocop do |_task|
    REPOSITORIES.each do |repository|
      FileUtils.cp('.rubocop.yml', "#{repository}/")
    end
  end

  task :license do |_task|
    REPOSITORIES.each do |repository|
      FileUtils.cp('LICENSE', "#{repository}/")
    end
  end
end
