require 'spec_helper'

describe FechUtils do

  describe ".regexify" do
    
    it "should convert symbols to anchored regular expressions" do
      regex = Fech.regexify(:date_coverage_from)
      regex.should == /^date_coverage_from$/i
    end
    
    it "should convert strings to unanchored regular expressions" do
      regex = Fech.regexify("date_coverage_from")
      regex.should == /date_coverage_from/i
    end
    
    it "should produce case-insensitive regular expressions" do
      regex = Fech.regexify(:date_coverage_from)
      regex.match("Date_coverage_FROM").size.should == 1
    end
    
    it "should return a custom regex if passed a row symbol defined in ROW_TYPES" do
      regex = Fech.regexify(:f3p)
      regex.should == FechUtils::ROW_TYPES[:f3p]
    end
    
  end

end