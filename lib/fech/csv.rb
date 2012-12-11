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

  class Csv

    # Loads a given file and parses it into an array, line by line.
    # Basic wrapper around FasterCSV.foreach
    # @param [String] file_path location of the filing on the file system
    # @options opts passed through to FasterCSV
    def self.parse_row(file_path, opts)
      foreach(file_path, clean_opts(opts)) { |row| yield row }
    end

    def self.clean_opts(opts)
      opts.reject {|k,v| ![:col_sep, :quote_char, :encoding].include?(k)}
    end

  end

  class CsvDoctor < Fech::Csv

    # Skips FasterCSV's whole-file wrapper, and passes each line in
    # the file to a function that will parse it individually.
    # @option opts [Boolean] :row_type yield only rows that match this type
    def self.parse_row(file_path, opts)
      File.open(file_path, "r:#{opts[:encoding]}").each do |line|
        # Skip empty lines
        next if line.strip.empty?

        # Skip non-matching row-types
        next if opts.key?(:row_type) && !Fech.regexify(opts[:row_type]).match(line)

        yield safe_line(line, clean_opts(opts))
      end
    end

    # Tries to parse the line with FasterCSV.parse_line and the given
    # quote_char. If this fails, try again with the "\0" quote_char.
    # @param [String] line the file's row to parse
    # @options opts :quote_char the quote_char to try initially
    def self.safe_line(line, opts)
      # :encoding isn't a valid argument to Csv#parse_line
      opts.delete(:encoding)
      begin
        parse_line(line, opts)
      rescue Fech::Csv::MalformedCSVError
        row = parse_line(line, clean_opts(opts).merge(:quote_char => "\0"))
        row.map! { |val| safe_value(val) }
      end
    end

    # Removes extraneous quotes from values.
    def self.safe_value(val)
      return val unless val.is_a?(String)
      begin
        parse_line(val).first
      rescue Fech::Csv::MalformedCSVError
        val
      end
    end

  end
end
