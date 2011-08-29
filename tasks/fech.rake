require 'fech'
require 'rspec'
require 'rspec/core/rake_task'

namespace :fech do
  
  desc "Recreate the column header maps from source .csv files"
  task :maps do
    # This will spit out a rendered mappings file, but will not be loaded by
    # the gem by default. To use the new file, move it into the lib/fech
    # folder of your active Fech gem.
    source = 'sources/'
    destination = ENV['destination'] || Dir.pwd
    
    if File.directory?(destination)
      destination = File.join(destination, 'rendered_maps.rb')
    end
    
    Fech::MapGenerator.convert_header_file_to_row_files(source)
    Fech::MapGenerator.dump_row_maps_to_ruby(source, destination)
    
    puts "Successfully wrote out mappings to #{destination}"
  end
  
  namespace :test do
    
    desc "Run all specs."
    RSpec::Core::RakeTask.new(:spec) do |t|
      t.pattern = 'spec/*_spec.rb'
      t.verbose = false
    end
    
    RSpec::Core::RakeTask.new(:coverage) do |t|
      t.rcov = true
      t.rcov_opts =  %w{--exclude gems\/,spec\/,features\/,seeds\/ --sort coverage}
      t.verbose = true
    end
    
  end
  
end
