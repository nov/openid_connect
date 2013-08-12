require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

namespace :cover_me do
  desc "Generates and opens code coverage report."
  task :report do
    require 'cover_me'
    CoverMe.complete!
  end
end

task :spec do
  Rake::Task['cover_me:report'].invoke unless ENV['TRAVIS_RUBY_VERSION']
end

task default: :spec