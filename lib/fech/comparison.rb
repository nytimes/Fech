module Fech
  # Fech::Comparison takes two Filing objects and does comparisons on them,
  # checking for differences between an original and amended filing, or 
  # two filings covering the same period in different years.
  class Comparison
    attr_accessor :filing_1, :filing_2
    
    # Create a new Comparison object by passing in two Filing objects
    # Filing objects need to be downloaded first
    # f1 = Fech::Filing.new(767437)
    # f1.download
    # f2 = Fech::Filing.new(751798)
    # f2.download
    # comparison = Fech::Comparison.new(f1, f2)
    # comparison.summary
    def initialize(filing_1, filing_2, opts={})
      @filing_1     = filing_1
      @filing_2     = filing_2
    end
    
    # compares summary of this filing with summary of an earlier
    # or later version of the filing, returning a Fech::Mapped hash
    # of mapped fields whose values have changed. based on rails' hash diff:
    # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/hash/diff.rb
    def summary
      @filing_1.summary.delete_if { |k, v| @filing_2.summary[k] == v }.merge!(@filing_2.summary.dup.delete_if { |k, v| @filing_1.summary.has_key?(k) })
    end
    
    # compares a schedule of itemized records from one filing to another
    # returns an array of records that are new or have changed.
    def schedule(schedule)
      @filing_1.rows_like(/schedule/) - @filing_2.rows_like(/schedule/)
    end
    
  end
end