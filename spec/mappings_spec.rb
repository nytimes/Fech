require 'spec_helper'

describe Fech::Mappings do
  
  describe "#for_row" do
    
    before do
      @mappings = Fech::Mappings.new
    end
    
    it "should return the correct row_map" do
      @mappings.for_row("sa").should == @mappings.map["^sa"]["^7.0|6.4"]
      @mappings.for_row("f3p31").should_not == @mappings.for_row("f3p")
    end
    
    it "should use a greedy match on the row type, matching most complete available option" do
      @mappings.for_row("f3p31").should == @mappings.map[FechUtils::ROW_TYPES[:f3p31].source]["^7.0|6.4|6.3|6.2|6.1"]
      @mappings.for_row("f3p").should == @mappings.map[FechUtils::ROW_TYPES[:f3p].source]["^7.0"]
    end
    
  end
  
  describe ".key_by_regex" do
    
    before do
      @hash = {
        "^foo$" => :foo,
        "bar" => :bar
      }
    end
    
    it "should match a key by regexp" do
      Fech::Mappings.key_by_regex(@hash, "foo").should == :foo
      Fech::Mappings.key_by_regex(@hash, "bar").should == :bar
      Fech::Mappings.key_by_regex(@hash, "foobar").should == :bar
    end
    
    it "raise error if key not found" do
      expect {
        Fech::Mappings.key_by_regex(@hash, "oof")
      }.to raise_error
    end
    
  end
  
end