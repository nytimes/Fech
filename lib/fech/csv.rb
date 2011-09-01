require 'csv'       if     RUBY_VERSION > '1.9'
require 'fastercsv' unless RUBY_VERSION > '1.9'

# Fech::Csv is a wrapper that provides simple CSV handling consistency
# between Ruby 1.8 and Ruby 1.9.
#
# 1.8's "FasterCSV" library has been brought into the Ruby core as of 1.9
# as "CSV".  The methods are the same so no overloading should be needed.
module Fech
  begin
    # Ruby 1.9 and up compatibility
    class Csv < CSV
    end
  rescue
    # 1.8 compatibility
    class Csv < FasterCSV
    end
  end
end
