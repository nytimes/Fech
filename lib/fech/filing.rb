require 'tmpdir'
require 'open-uri'

module Fech
  
  # Fech::Filing downloads an Electronic Filing given its ID, and will search
  # rows by row type. Using a child Translator object, the data in each row
  # is automatically mapped at runtime into a labeled Hash. Additional
  # Translations may be added to change the way that data is mapped and cleaned.
  class Filing
    attr_accessor :filing_id, :download_dir, :translator

    # Create a new Filing object, assign the download directory to system's
    # temp folder by default.
    # @param [String] download_dir override the directory where files should
    #   be downloaded.
    # @param [Symbol,Array] translate a list of built-in translation sets to use
    def initialize(filing_id, opts={})
      @filing_id    = filing_id
      @download_dir = opts[:download_dir] || Dir.tmpdir
      @translator   = Fech::Translator.new(:include => opts[:translate])
      @quote_char   = opts[:quote_char] || '"'
      @csv_parser   = opts[:csv_parser] || Fech::Csv
    end

    # Saves the filing data from the FEC website into the default download
    # directory.
    def download
      File.open(file_path, 'w') do |file|
        file << open(filing_url).read
      end
      self
    end
    
    # Access the header (first) line of the filing, containing information
    # about the filing's version and metadata about the software used to file it.
    # @return [Hash] a hash that assigns labels to the values of the filing's header row
    def header(opts={})
      each_row do |row|
        return parse_row?(row)
      end
    end
    
    # Access the summary (second) line of the filing, containing aggregate and
    # top-level information about the filing.
    # @return [Hash] a hash that assigns labels to the values of the filing's summary row
    def summary
      each_row_with_index do |row, index|
        next if index == 0
        return parse_row?(row)
      end
    end
    
    # Access all lines of the filing that match a given row type. Will return an
    # Array of all available lines if called directly, or will yield the mapped
    # rows one by one if a block is passed.
    #
    # @param [String, Regexp] row_type a partial or complete name of the type of row desired
    # @option opts [Boolean] :raw should the function return the data as an array
    #   that has not been mapped to column names
    # @option opts [Array] :include list of field names that should be included
    #   in the returned hash
    # @yield [Hash] each matched row's data, as either a mapped hash or raw array
    # @return [Array] the complete set of mapped hashes for matched lines
    def rows_like(row_type, opts={}, &block)
      data = []
      each_row do |row|
        value = parse_row?(row, opts.merge(:parse_if => row_type))
        next if value == false
        if block_given?
          yield value
        else
          data << value if value
        end
      end
      block_given? ? nil : data
    end
    
    # Decides what to do with a given row. If the row's type matches the desired
    # type, or if no type was specified, it will run the row through #map.
    # If :raw was passed true, a flat, unmapped data array will be returned.
    #
    # @param [String, Regexp] row a partial or complete name of the type of row desired
    # @option opts [Array] :include list of field names that should be included
    #   in the returned hash
    def parse_row?(row, opts={})
      # Always parse, unless :parse_if is given and does not match row
      if opts[:parse_if].nil? || \
          Fech.regexify(opts[:parse_if]).match(row.first.downcase)
        opts[:raw] ? row : map(row, opts)
      else
        false
      end
    end

    # Maps a raw row to a labeled hash following any rules given in the filing's
    # Translator based on its version and row type.
    # Finds the correct map for a given row, performs any matching Translations
    # on the individual values, and returns either the entire dataset, or just
    # those fields requested.
    # @param [String, Regexp] row a partial or complete name of the type of row desired
    # @option opts [Array] :include list of field names that should be included
    #   in the returned hash
    def map(row, opts={})
      data = Fech::Mapped.new(self, row.first)
      full_row_map = map_for(row.first)
      
      # If specific fields were asked for, return only those
      if opts[:include]
        row_map = full_row_map.select { |k| opts[:include].include?(k) }
      else
        row_map = full_row_map
      end
      
      # Inserts the row into data, performing any specified preprocessing
      # on individual cells along the way
      row_map.each_with_index do |field, index|
        value = row[full_row_map.index(field)]
        translator.get_translations(:row => row.first,
            :version => filing_version, :action => :convert,
            :field => field).each do |translation|
          # User's Procs should be given each field's value as context
          value = translation[:proc].call(value)
        end
        data[field] = value
      end
      
      # Performs any specified group preprocessing / combinations
      combinations = translator.get_translations(:row => row.first,
            :version => filing_version, :action => :combine)
      row_hash = hash_zip(row_map, row) if combinations
      combinations.each do |translation|
        # User's Procs should be given the entire row as context
        value = translation[:proc].call(row_hash)
        field = translation[:field].source.gsub(/[\^\$]*/, "").to_sym
        data[field] = value
      end
      
      data
    end
    
    # Returns the column names for given row type and the filing's version
    # in the order they appear in row data.
    # @param [String, Regexp] row_type representation of the row desired
    def map_for(row_type)
      mappings.for_row(row_type)
    end
    
    # Returns the column names for given row type and version in the order
    # they appear in row data.
    # @param [String, Regexp] row_type representation of the row desired
    # @option opts [String, Regexp] :version representation of the version desired
    def self.map_for(row_type, opts={})
      Fech::Mappings.for_row(row_type, opts)
    end
    
    # @yield [t] returns a reference to the filing's Translator
    # @yieldparam [Translator] the filing's Translator
    def translate(&block)
      if block_given?
        yield translator
      else
        translator
      end
    end
    
    # Whether this filing amends a previous filing or not.
    def amendment?
      !amends.nil?
    end
    
    # Returns the filing ID of the past filing this one amends,
    # nil if this is a first-draft filing.
    # :report_id in the HDR line references the amended filing
    def amends
      header[:report_id]
    end
    
    # compares summary of this filing with summary of an earlier
    # or later version of the filing, returning a hash of mapped 
    # fields whose values have changed.
    def compare(other_filing_id)
      other_filing = Fech::Filing.new(other_filing_id)
      other_filing.download
      summary.hash_diff(other_filing.summary).keys
    end
    
    # Returns a hash that represents the difference between two hashes.
    def hash_diff(h2)
      dup.delete_if { |k, v| h2[k] == v }.merge!(h2.dup.delete_if { |k, v| has_key?(k) })
    end
    
    # Combines an array of keys and values into an Fech::Mapped object,
    # a type of Hash.
    # @param [Array] keys the desired keys for the new hash
    # @param [Array] values the desired values for the new hash
    # @return [Fech::Mapped, Hash]
    def hash_zip(keys, values)
      Fech::Mapped.new(self, values.first).merge(Hash[*keys.zip(values).flatten])
    end
    
    # The version of the FEC software used to generate this Filing
    def filing_version
      @filing_version ||= parse_filing_version
    end
    
    # Pulls out the version number from the header line.
    # Must parse this line manually, since we don't know the version yet, and
    # thus the delimiter type is still a mystery.
    def parse_filing_version
      first = File.open(file_path).first
      if first.index("\034").nil?
        @csv_parser.parse(first).flatten[2]
      else
        @csv_parser.parse(first, :col_sep => "\034").flatten[2]
      end
    end
    
    # Gets or creats the Mappings instance for this filing_version
    def mappings
      @mapping ||= Fech::Mappings.new(filing_version)
    end

    # The location of the Filing on the file system
    def file_path
      File.join(download_dir, file_name)
    end

    def file_name
      "#{filing_id}.fec"
    end

    def filing_url
      "http://query.nictusa.com/dcdev/posted/#{filing_id}.fec"
    end

    # Iterates over and yields the Filing's lines
    # @option opts [Boolean] :with_index yield both the item and its index
    # @yield [Array] a row of the filing, split by the delimiter from #delimiter
    def each_row(opts={}, &block)
      unless File.exists?(file_path)
        raise "File #{file_path} does not exist. Try invoking the .download method on this Filing object."
      end

      c = 0
      @csv_parser.parse_row(file_path, :col_sep => delimiter, :quote_char => @quote_char, :skip_blanks => true) do |row|
        if opts[:with_index]
          yield [row, c]
          c += 1
        else
          yield row
        end
      end
    end

    # Wrapper around .each_row to include indexes
    def each_row_with_index(&block)
      each_row(:with_index => true, &block)
    end
    
    # @return [String] the delimiter used in the filing's version
    def delimiter
      filing_version.to_f < 6 ? "," : "\034"
    end
    
  end
end
