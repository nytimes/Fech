module Fech
  
  # Stores sets of build-in translations that can be mixed in to a Fech::Filing.
  # Contains functions that accept a Translator, and add arbitrary translations
  # to it. The public function names should correspond to the key used to mix it in.
  #
  # filing = Fech::Filing.new(XXXXXX, :translate => [:names, :dates])
  class DefaultTranslations

    # The five bits that make up a name, and their labels in the People gem
    NAME_BITS = [:prefix, :first_name, :middle_name, :last_name, :suffix]
    PEOPLE_BITS = [:title, :first, :middle, :last, :suffix]
    
    attr_reader :t
    
    def initialize(translator)
      @t = translator
    end
    
    # Splits composite names into its component parts, and combines those parts
    # into composites where appropriate. Assumes that the canonical names of the
    # fields follow the pattern:
    #   * FIELD_name         - "Mr. John Charles Smith Sr."
    #   * FIELD_prefix       - "Mr."
    #   * FIELD_first_name   - "John"
    #   * FIELD_middle_name  - "Charles"
    #   * FIELD_last_name    - "Smith"
    #   * FIELD_suffix       - "Sr."
    def names
      
      # COMBINE split names into composite names for these rows
      composites = [
        {:row => :sa,     :version => /^[6-8]/,   :field => [:contributor, :donor_candidate]},
        {:row => :sb,     :version => /^[6-8]/,   :field => [:payee, :beneficiary_candidate]},
        {:row => :sc,     :version => /^[6-8]/,   :field => [:lender, :lender_candidate]},
        {:row => :sc1,    :version => /^[6-8]/,   :field => [:treasurer, :authorized]},
        {:row => :sc2,    :version => /^[6-8]/,   :field => :guarantor},
        {:row => :sd,     :version => /^[6-8]/,   :field => :creditor},
        {:row => :se,     :version => /^[6-8]/,   :field => [:payee, :candidate]},
        {:row => :sf,     :version => /^[6-8]/,   :field => [:payee, :payee_candidate]},
        {:row => :f3p,    :version => /^[6-8]/,   :field => :treasurer},
        {:row => :f3p31,  :version => /^[6-8]/,   :field => :contributor},
      ]
      # SPLIT composite names into component parts for these rows
      components = [
        {:row => :sa,     :version => /^3|(5.0)/, :field => :contributor},
        {:row => :sa,     :version => /^[3-5]/,   :field => :donor_candidate},
        {:row => :sb,     :version => /^3|(5.0)/, :field => :payee},
        {:row => :sb,     :version => /^[3-5]/,   :field => :beneficiary_candidate},
        {:row => :sc,     :version => /^[3-5]/,   :field => [:lender, :lender_candidate]},
        {:row => :sc1,    :version => /^[3-5]/,   :field => [:treasurer, :authorized]},
        {:row => :sc2,    :version => /^[3-5]/,   :field => :guarantor},
        {:row => :sd,     :version => /^[3-5]/,   :field => :creditor},
        {:row => :se,     :version => /^[3-5]/,   :field => [:payee, :candidate]},
        {:row => :sf,     :version => /^[3-5]/,   :field => [:payee, :payee_candidate]},
        {:row => :f3p,    :version => /^[3-5]/,   :field => :treasurer},
        {:row => :f3p31,  :version => /^[3-5]/,   :field => :contributor},
      ]
      
      composites.each { |c| combine_components_into_name(c) }
      components.each { |c| split_name_into_components(c) }
      
    end
    
    # Converts everything that looks like an FEC-formatted date to a
    # native Ruby Date object.
    def dates
      # only convert fields whose name is date* or *_date*
      # lots of other things might be 8 digits, and we have to exclude eg 'candidate'
      t.convert :field => /(^|_)date/ do |value|
        unless value.nil?
          Date.parse(value) rescue value
        end
      end
    end
    
    private
    
    # Turns "Allred^Ann^Mrs.^III" into "Mrs. Ann Allred III"
    def self.fix_carrot_names(name)
      name = name.split("^").reverse
      # move the suffix to the beginning
      name.push name.shift if name.size > 3
      name.join(" ")
    end
    
    # Create a Translation for the given row, version named as :field
    def combine_components_into_name(composite)
      raise ArgumentError, "Must pass a :row, :version AND :field" if composite.nil?
      composite[:field] = [composite[:field]] unless composite[:field].is_a?(Array)
      
      composite[:field].each do |field|
        t.combine(:row => composite[:row], :version => composite[:version],
                  :field => "#{field}_name") do |row|
                  
          # Gather each name_bit from the parsed row, and join it into one value
          bits = NAME_BITS.collect do |field_name|
            row.send("#{field}_#{field_name}".to_sym)
          end
          bits.compact.join(" ")
        end
      end
    end
    
    # Create a Translation for all five name bits, that will strip
    # out its respective bit from an already-populate composite name field.
    def split_name_into_components(component)
      raise ArgumentError, "Must pass a :row, :version AND :field" if component.nil?
      component[:field] = [component[:field]] unless component[:field].is_a?(Array)
      
      component[:field].each do |field|
        NAME_BITS.zip(PEOPLE_BITS).each do |field_name, people_name|
          t.combine(:row => component[:row], :version => component[:version],
                    :field => "#{field}_#{field_name}") do |row|
          
            # Grab the original, composite name
            name = row.send("#{field}_name")
          
            unless name.nil?
              # Fix various name formatting errors
              name = self.class.fix_carrot_names(name) unless name.index("^").nil?
          
              # Extract just the component you want
              (Fech::Translator::NAME_PARSER.parse(name)[people_name] || "").strip
            else
              nil
            end
          end
        end
      end
    end
    
  end
  
end
