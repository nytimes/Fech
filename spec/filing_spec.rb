require 'spec_helper'

describe Fech::Filing do
  
  before do
    @filing = Fech::Filing.new(723604)
    @filing.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', '723604.fec'))
    @filing8 = Fech::Filing.new(748730)
    @filing8.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', '748730.fec'))
  end
  
  describe "#filing_version" do
    
    it "should return the correct filing version" do
      @filing.send(:filing_version).should == "7.0"
      @filing8.send(:filing_version).should == "8.0"
    end
    
    it "should parse the file only once" do
      @filing.expects(:parse_filing_version).once.returns("7.0")
      @filing.send(:filing_version)
      @filing.send(:filing_version)
    end
    
  end
  
  describe ".hash_zip" do
    
    it "should zip the given keys and values into a hash" do
      @filing = Fech::Filing.new(723604)
      keys = [:one,:three,:two]
      values = [1, 3, 2]
      @filing.hash_zip(keys, values).should == {:one => 1, :two => 2, :three => 3}
    end
    
  end
  
  describe "#summary" do
    
    it "should return the mapped summary row" do
      sum = @filing.summary
      sum.should be_a_kind_of(Hash)
      sum[:form_type].should == "F3PN"
    end
  end
  
  describe "#mappings" do
    
    it "should create a new Mappings instance with correct version" do
      @filing.send(:mappings).version.should == "7.0"
    end
    
    it "should memoize itself" do
      mapping = Fech::Mappings.new
      Fech::Mappings.expects(:new).once.returns(mapping)
      @filing.send(:mappings)
      @filing.send(:mappings)
    end
    
  end
  
  describe "#rows_like" do
    
    it "should return only rows matching the specified regex" do
      @filing.rows_like(/^sa/).size.should == 1
      @filing.rows_like(/^s/).size.should == 2
      @filing.rows_like(/^sc/).size.should == 0
    end
    
    it "should return an array if no block is given" do
      @filing.rows_like(/^s/).class.should == Array
    end
    
    it "should return empty array if no matches found" do
      @filing.rows_like(/^sc/).should == []
    end
    
    it "should yield hashes of row values if passed a block" do
      @filing.rows_like(/^sa/) do |c|
        c.should be_a_kind_of(Hash)
      end
    end
    
    it "should allow case-insensitive string input" do
      @filing.rows_like("Sa17a").size.should be > 0
    end
    
  end
  
  describe "#parse_row?" do
    
    before do
      f = open(@filing.file_path, 'r')
      f.readline
      @row = f.readline.split(@filing.delimiter)
      f.close
    end
    
    it "should return the mapped row" do
      @filing.send(:parse_row?, @row).should be_a_kind_of(Hash)
    end
    
    describe "when :parse_if is specified" do
      
      it "should return the mapped row if :parse_if matches row type" do
        @filing.send(:parse_row?, @row, {:parse_if => /^f3p/}).should be_a_kind_of(Hash)
      end
      
      it "should return false if row was skipped" do
        @filing.send(:parse_row?, @row, {:parse_if => /^sa/}).should == false
      end
      
    end
    
    it "should return the raw row data if :raw is true" do
      @filing.send(:parse_row?, @row, {:raw => true}).class.should == Array
    end
    
  end
  
  describe "#map_for" do
    
    it "should return the correct map for given row type" do
      map = @filing.map_for(/sa/)
      map.class.should == Array
      map.first.should == :form_type
    end
    
    it "should raise error if no map is found" do
      lambda { @filing.map_for(/sz/) }.should raise_error
    end
    
  end
  
  describe ".map_for" do
    
    it "should return the correct map for given row type" do
      map = Fech::Filing.map_for(/sa/)
      map.class.should == Array
      map.first.should == :form_type
    end
    
    it "should raise error if no map is found" do
      lambda { Fech::Filing.map_for(/sz/) }.should raise_error
    end
    
    it "should allow choice of version" do
      v7 = Fech::Filing.map_for(/sa/, :version => 7.0)
      v6 = Fech::Filing.map_for(/sa/, :version => 6.1)
      v6.should_not == v7
    end
    
  end
  
  describe "#map" do
    
    before do
      f = open(@filing.file_path, 'r')
      f.readline
      @f3p_row = f.readline.split(@filing.delimiter)
      @sa_row = f.readline.split(@filing.delimiter)
      f.close
    end
    
    it "should map the data in row to named values according to row_map" do
      row_map = @filing.send(:mappings).for_row(@sa_row.first)
      mapped = @filing.send(:map, @sa_row)
      mapped.should be_a_kind_of(Hash)
      
      mapped[:form_type].should == "SA17A"
      mapped[:contributor_state].should == "SC"
    end
    
    it "should perform conversion translations" do
      row_map = @filing.send(:mappings).for_row(@sa_row.first)
      @filing.translate do |t|
        t.convert(:row => @sa_row.first, :field => :contribution_date) do |v|
          Date.parse(v)
        end
      end
      mapped = @filing.send(:map, @sa_row)
      mapped[:contribution_date].should == Date.parse("20110322")
    end
    
    it "should perform combination translations" do
      @filing.translate do |t|
        t.combine(:row => @f3p_row.first, :field => :net_individual_contributions) do |row|
          row[:col_a_17_a_iii_individual_contribution_total].to_f - row[:col_a_28_a_individuals].to_f
        end
      end
      mapped = @filing.send(:map, @f3p_row)
      mapped[:net_individual_contributions].should == mapped[:col_a_17_a_iii_individual_contribution_total].to_f - mapped[:col_a_28_a_individuals].to_f
    end
    
    it "should return only field asked for if :include was specified" do
      fields = [:form_type, :filer_committee_id_number, :transaction_id]
      mapped = @filing.send(:map, @sa_row, :include => fields)
      fields.each do |field|
        mapped[field].should_not be_nil
      end
      mapped.size.should == 3
    end
    
  end
  
  describe "amendments" do
    
    before do
      @filing = Fech::Filing.new(723604)
      @filing.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', '723604.fec'))
    end
    
    describe "for non-amending filings" do
      
      describe "#amendment?" do
        it "should return false" do
          @filing.stubs(:header).returns({:report_id => nil})
          @filing.amendment?.should == false
        end
      end
      
    end
    
    describe "#amends" do
      
      it "should return nil for filings without a report_id in HDR" do
        @filing.stubs(:header).returns({:report_id => nil})
        @filing.amends.should == nil
      end
  
      it "should return a filing_id for filings with a report_id in HDR" do
        @filing.stubs(:header).returns({:report_id => "723603"})
        @filing.amends.should == "723603"
      end
      
    end
    
    describe "#amendment?" do
  
      it "should return false for filings without a report_id in HDR" do
        @filing.stubs(:header).returns({:report_id => nil})
        @filing.amendment?.should == false
      end
  
      it "should return true for filings with a report_id in HDR" do
        @filing.stubs(:header).returns({:report_id => "723603"})
        @filing.amendment?.should == true
      end
    
    end
    
  end
  
end