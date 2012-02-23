require 'spec_helper'

describe Fech::Comparison do

  describe "compare" do
    before do
      @amended_filing = Fech::Filing.new(767339)
      @amended_filing.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', '767339.fec'))
      @original_filing = Fech::Filing.new(467627)
      @original_filing.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', '467627.fec'))
      @comparison = Fech::Comparison.new(@amended_filing, @original_filing)
    end
    
    it "should return a hash of columns and values that have changed for two filings" do
      @comparison.summary.class.should == Fech::Mapped
      @comparison.summary[:col_a_net_contributions].should == "542344.49"
    end
    
    it "should return an array of schedule items that have changed" do
      @comparison.schedule(:sa).size.should == 576
      @comparison.schedule("sb").size.should == 60
    end
    
    it "should return an empty array of schedule items when none have changed" do
      @comparison.schedule("sc").size.should == 0
    end
    
  end

end