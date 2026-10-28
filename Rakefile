require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc 'Bump patch version'
task :patch do
  system 'gem bump --tag'
end

desc 'Bump minor version'
task :minor do
  system 'gem bump --version minor --tag'
end

desc 'Bump major version'
task :major do
  system 'gem bump --version major --tag'
end

task publish: [:build] do
  $VERBOSE = nil
  load 'live_set/version.rb'
  system "gem push pkg/live_set-#{LiveSet::VERSION}.gem"
end

desc 'Release a new version: bump the major version, create a git tag, build the gem and release it to geminabox'
task release_major: %i[test major publish]

desc 'Release a new version: bump the minor version, create a git tag, build the gem and release it to geminabox'
task release_minor: %i[test minor publish]

desc 'Release a new version: bump the patch version, create a git tag, build the gem and release it to geminabox (default)'
task release_patch: %i[test patch publish]

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = 'spec/**/*_spec.rb'
end

desc 'Run the test suite'
task test: :spec

task default: :test
