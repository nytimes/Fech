require 'spec_helper'

describe Fech::Mapped do
  
  before do
    @f = Fech::Filing.new(723604)
    @f.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', '723604.fec'))
  end
  
  describe "@filing" do
    
    it "should get set to the calling filing" do
      header = @f.header
      header.should be_a_kind_of Fech::Mapped
      header.filing.should == @f
    end
    
  end
  
  describe "[]" do
    
    it "should obey aliases in the filing's translator" do
      @f.translate do |t|
        t.alias :version, :fec_version, "hdr"
      end
      
      header = @f.header
      header[:version].should == header[:fec_version]
    end
    
    it "should detect the most recent alias first" do
      @f.translate do |t|
        t.alias :version, :fec_version, "hdr"
        t.alias :version, :report_id, "hdr"
      end
      
      header = @f.header
      header[:version].should_not == header[:fec_version]
      header[:version].should == header[:report_id]
    end
    
  end
  
end