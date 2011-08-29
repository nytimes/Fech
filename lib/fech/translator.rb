require 'people'

module Fech
  
  # Fech::Translator stores a collection of Procs which are associated with
  # one or many field types, row types and filing versions. When a row that
  # matches all of these is mapped in Filing, the Proc is run on that value.
  #
  # :action => :convert alters a single value in place.
  #            :combine creates a new row out of others.
  #
  # It also stores a set of aliases, allowing fields on the returned Hash of
  # mapped data to be accessed by other names.
  class Translator
    
    attr_accessor :translations, :aliases, :cache
    
    NAME_PARSER = People::NameParser.new
    
    def initialize(opts = {})
      @cache        = {}
      @aliases      = []
      @translations = []
      # op-in default translation packs
      add_default_translations(opts[:include] || [])
    end
    
    # Returns list of all translations that should be applied to values of
    # specified row and field.
    #
    # @option opts [String] :field the current field's value
    # @option opts [String] :version the current filing's version
    # @option opts [String] :row the row type
    # @option opts [Symbol] :action match only :combine or :convert translations
    def get_translations(opts)
      key = [:field, :row, :version, :action].collect { |key| opts[key] }.join(":")
      @cache[key] ||= \
      procs = translations.collect do |t|
        t if self.class.applicable_translation?(t, opts)
      end.compact
    end
    
    # Given a translation and any or all of field, version, row, action:
    # Returns true if all the given options are compatible with those
    # specified in the translation.
    #
    # @param [Hash] translation the translation being tested for relevance
    # @option opts [String] :field the current field's value
    # @option opts [String] :version the current filing's version
    # @option opts [String] :row the row type
    # @option opts [Symbol] :action match only :combine or :convert translations
    def self.applicable_translation?(translation, opts)
      opts.keys.all? { |k| translation[k].match(opts[k].to_s) }
    end

    # Adds a tranlation for preprocessing a single field's value
    # 
    # t.convert(:row => /^sa/, :field => :date_coverage_from) { |v| Date.parse(v) }
    #
    # @option opts [String] :field the current field's value
    # @option opts [String] :version the current filing's version
    # @option opts [String] :row the row type
    def convert(args={}, &block)
      add_translation(args.merge(:action => :convert), &block)
    end
    
    # Adds a translation that uses other fields to create a new one
    # 
    # t.combine(:row => "sa", :field => :net_individual_contributions) do |row|
    #   row.individual_contributions - row.individual_refunds
    # end
    #
    # @option opts [String] :field the name of the field to create
    # @option opts [String] :version the current filing's version
    # @option opts [String] :row the row type
    def combine(args={}, &block)
      add_translation(args.merge(:action => :combine), &block)
    end
    
    # Allows @old_name on @row to be accessible on the returned hash as @new_name
    # 
    # t.alias(:new, :old, "sa")
    #
    # @param [Symbol] new_name the given field will be accessible using this token
    # @param [Symbol] old_name the existing field whose value to alias
    # @param [Symbol,Regex] row the types of rows this alias should be applied to
    def alias(new_name, old_name, row=/.*/)
      aliases << {
        :row => Fech.regexify(row),
        :alias => new_name,
        :for => old_name
      }
    end
    
    private
    
    # Adds a translation to the global translation list.
    # Åt runtime, any field whose field, row and version match a translation
    # will have its value preprocessed through &block.
    #
    # @option data [String] :field the current field's value
    # @option data [String] :version the current filing's version
    # @option data [String] :row the row type
    def add_translation(data, &block)
      raise "Block required" unless block_given?
      
      # The cache may be now be out of date after adding this translation
      cache = {}
      
      data            ||= {}
      data[:row]      ||= /.*/
      data[:field]    ||= /.*/
      data[:version]  ||= /.*/
      
      # Convert any string or symbols to regular expressions for the hash
      data.each do |k,v|
        data[k] = Fech.regexify(v)
      end
      
      data = data.merge(:proc => block)
      translations << data
      data
    end
    
    # For each default translation set given, execute the corresponding
    # code in Fech::DefaultTranslations.
    def add_default_translations(translations_list)
      translations_list = [translations_list] unless translations_list.is_a?(Array)
      return if translations_list.empty?
      
      default = Fech::DefaultTranslations.new(self)
      translations_list.each do |package|
        default.send(package)
      end
    end
    
  end
end