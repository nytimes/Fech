module Fech
  class VersionError < RuntimeError; end
  
  # Fech::Mappings loads a set of master mappings between labels and where
  # their values can be found in Electronic Filings for various row types
  # and versions.
  # To access a map, call Mappings.for_row with the row_type,
  # and optionally the version:
  #   Mappings.for_row("SA", :version => 6.1)
  class Mappings
    
    attr_accessor :map, :version
    
    def initialize(ver = Fech::DEFAULT_VERSION)
      @version  = ver
      @map      = load_map
      @cache    = {}
    end
    
    # Returns a hash of mappings for row with given row_type
    #
    # @param [String,Symbol] row_type the row type whose map to find
    def for_row(row_type)
      @cache[row_type] ||= self.class.for_row(row_type, :version => @version)
    end
    
    # Returns the basic, default mappings hash by reading in a mappings
    # file and saving the variable to the class's context.
    def load_map
      self.class.load_map
    end
    
    def self.load_map
      Fech::RENDERED_MAPS
    end
    
    # Given a row type, first find the entire block of maps for that row type.
    # Then, use the filing's version to choose which specific map set to use,
    # and return it.
    #
    # @param [Symbol,String,Regex] row_type the row whose map to find
    def self.for_row(row_type, opts={})
      opts[:version] ||= Fech::DEFAULT_VERSION
      map = key_by_regex(load_map, row_type)
      key_by_regex(map, opts[:version])
    end
    
    # Given a Hash whose keys are string representations of regular expressions,
    # return the value whose key best matches the given label.
    #
    # @param [Hash] hash a Hash with string regular expressions for keys
    # @param [String,Symbol,Regexp] label return the key that best matches this
    def self.key_by_regex(hash, label)
      label = label.source if label.is_a?(Regexp)
      
      # Try matching longer keys first, to ensure more accurate keys are
      # prioritized over less accurate ones.
      hash.keys.sort { |x, y| x.length <=> y.length }.reverse.each do |key|
        return hash[key] if Regexp.new(key, Regexp::IGNORECASE).match(label.to_s)
      end
      
      raise VersionError, "Attempted to access mapping that has not been generated (#{label}). " +
            "Supported keys match the format: #{hash.keys.join(', ')}"
    end
    
  end
end
