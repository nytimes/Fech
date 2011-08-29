require 'spec_helper'

describe Fech::MapGenerator do
  
  describe ".generate_row_map_from_file" do
    
    before do
      @mg = Fech::MapGenerator.new
      @row = "sa"
      @source_dir = File.join(File.dirname(__FILE__), 'sources', @row + '.csv')
      Fech::MapGenerator.stubs(:row_map_file).returns(@source_dir)
    end
    
    it "should not raise error on bad data" do
      lambda {
        Fech::MapGenerator.generate_row_map_from_file(@source_dir, @row)
      }.should_not raise_error
    end
    
    it "should skip rows without a canonical name" do
      row_map = Fech::MapGenerator.generate_row_map_from_file(@source_dir, @row)
      row_map["^7"].should == [:form_type, :date_coverage_from, :aggregate]
    end
    
    it "should skip columns without a version_type header" do
      row_map = Fech::MapGenerator.generate_row_map_from_file(@source_dir, @row)
      row_map.keys.should =~ ["^7", "^6", "^[2-5]"]
    end
    
    it "should not add items where there is no index" do
      row_map = Fech::MapGenerator.generate_row_map_from_file(@source_dir, @row)
      row_map["^6"][1].should be_nil
    end
    
  end
  
 describe ".convert_header_file_to_row_files" do
    before do
      @source_dir = File.join(File.dirname(__FILE__), 'sources')
    end
    it "should not raise error" do
      Fech::MapGenerator.convert_header_file_to_row_files(@source_dir)
      lambda {
        Fech::MapGenerator.convert_header_file_to_row_files(@source_dir)
      }.should_not raise_error
    end
  end

end