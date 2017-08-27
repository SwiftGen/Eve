require 'octokit'

namespace :sync do
  desc 'Synchronize the github issue labels for all repositories'
  task :labels, %i[repo_slug dry_run] do |_task, args|
    args.with_defaults(:dry_run => 'false')

    repo_slug = args[:repo_slug]
    dry_run = args[:dry_run].to_bool

    unless repo_slug
      puts '[!] A repo slug is required'
      puts 'Usage: rake labels:sync[User/RepoName,true|false]'
      exit 2
    end

    begin
      token = File.read('github_access_token')
    rescue
      puts "You must store your GitHub access token in the gitignored 'github_access_token' file next to ths script."
      exit 1
    end

    client = Octokit::Client.new(:access_token => token)

    LABELS = {
      'difficulty: easy' => 'bfe5bf',
      'difficulty: medium' => 'fad8c7',
      'difficulty: hard' => 'd4c5f9',
      'status: awaiting input' => 'fbca04',
      'status: help wanted' => 'fbca04',
      'status: ready to merge (waiting for CI)' => 'c2e0c6',
      'status: won\'t fix' => 'ffffff',
      'status: WIP' => 'fef2c0',
      'type: Apple bug' => 'e11d21',
      'type: bug/fix' => 'ee0701',
      'type: documentation' => 'bfdadc',
      'type: enhancement' => '84b6eb',
      'type: internal' => 'f9d0c4',
      'type: question' => 'cc317c',
      'change: breaking' => 'b60205'
    }.freeze

    missing_labels = LABELS.keys.dup
    extra_labels = []

    puts 'Retrieving existing labels…'
    labels = client.labels(repo_slug)

    # Update existing labels
    labels.each do |label|
      color = LABELS[label.name]
      if color.nil?
        extra_labels << label
      else
        missing_labels.delete(label.name)
        if label.color == color
          puts "  👍  `#{label.name}`"
        else
          puts "  🎨  `#{label.name}` (#{label.color} => #{color})"
          client.update_label(repo_slug, label.name, :color => color) unless dry_run
        end
      end
    end

    # Add missing labels
    missing_labels.each do |label_name|
      puts "  ⬆️  `#{label_name}`"
      client.add_label(repo_slug, label_name, LABELS[label_name]) unless dry_run
    end

    puts 'Done.'

    # List unexpected labels
    unless extra_labels.empty?
      puts 'Extra labels found:'
      puts extra_labels.map { |label| " - #{label.name}" }.join("\n")
    end
  end
end
