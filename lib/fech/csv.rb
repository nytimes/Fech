require 'fastercsv' unless RUBY_VERSION > '1.9'
require 'csv'       if     RUBY_VERSION > '1.9'

module Fech
  begin
    class Csv < CSV
    end
  rescue
    class Csv < FasterCSV
    end
  end
end
