module Fech
  
  # Fech::Mapped is a thin wrapper around Hash which allows values to be
  # referenced either by key or by an alias specified in the associated
  # Filing's Translations.
  class Mapped < Hash
    
    attr_accessor :filing, :row_type
    alias :old_bracket :[]
    
    def initialize(filing, row_type)
      @filing   = filing
      @row_type = row_type
    end
    
    # Just calls Hash's [] method, unless the specified key doesn't
    # exist, in which case it checks for any aliases on the filing's
    # translator.
    def [](key, &block)
      if has_key?(key)
        old_bracket(key, &block)
      else
        # Look up aliases in reverse, to find the most recent one
        # Does not allow (obvious) recursion
        aliias = filing.translator.aliases.reverse.detect do |a|
          a[:alias] == key && a[:row].match(row_type) && a[:alias] != a[:for]
        end if filing.translator
        # Pass the key this alias references back to this function
        aliias ? old_bracket(aliias[:for], &block) : nil
      end
    end
    
    def method_missing(method, *args, &block)
      self[method]
    end
    
  end
end
