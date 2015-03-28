require 'bundler'
require 'rspec/core/rake_task'
Bundler::GemHelper.install_tasks
Dir.glob('tasks/*.rake').each { |r| import r }

task :default => :spec
