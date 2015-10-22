require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rubocop/rake_task'

desc 'Run RuboCop on the lib directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb']
end

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = "-f d -c"
end

task default: [:spec, :rubocop]
