require 'spec_helper'

describe Fech::Translator do
  
  describe "#add_translation" do
    
    before do
      @translator = Fech::Translator.new
    end

    it "should ignore case when specified options are regular expressions" do
      @translator.convert(:row => /^foo/, :field => 'bar') {}
      @translator.get_translations(:row => "FoO", :field => 'bar', :action => :convert).size.should == 1
    end
    
  end
    
  describe ".convert" do
    
    before do
      @translator = Fech::Translator.new
    end
    
    it "should add a new translation to instance's list" do
      lambda {
        @translator.convert(:row => 'foo', :field => 'bar') {}
      }.should change{@translator.translations.count}.by(1)
    end
    
    it "should save a given block as part of the translation" do
      lambda {
        @translator.convert(:row => 'foo', :field => 'bar') {|v| Date.parse(v)}
      }.should_not raise_error
      @translator.translations.first[:proc].should_not be_nil
    end
    
    it "should raise error if no block is given" do
      lambda {
        @translator.convert(:row => 'foo', :field => 'bar')
      }.should raise_error
    end
    
    it "should not fail if not passed any limiting parameters" do
      lambda {
        @translator.convert {}
      }.should_not raise_error
    end
    
    it "should set defaults for unspecified parameters" do
      @translator.convert {}
      t = @translator.translations.last
      t[:row].should == /.*/i
      t[:field].should == /.*/i
      t[:version].should == /.*/i
    end
    
    it "should return the translation hash" do
      ret = @translator.convert {}
      ret.class.should == Hash
      ret.keys.should =~ [:row, :field, :version, :proc, :action]
    end
    
  end
  
  describe ".combine" do
    
    before do
      @filing = Fech::Filing.new(723604)
      @filing.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', '723604.fec'))
    end
    
    it "should correctly compute derived fields" do
      @filing.translator.combine(:row => /F3PN/, :field => :combined) do |row|
        Date.parse(row[:coverage_through_date]) - Date.parse(row[:coverage_from_date])
      end
      original = Date.parse(@filing.summary.coverage_through_date) - Date.parse(@filing.summary.coverage_from_date)
      @filing.summary.combined.should == original
    end
    
    it "should allow indexing by original field name" do
      @filing.translator.combine(:row => /F3PN/, :field => :combined) do |row|
        Date.parse(row[:coverage_through_date]) - Date.parse(row[:coverage_from_date])
      end
      lambda {
        @filing.summary.coverage_through_date
      }.should_not raise_error
    end
    
    it "should allow indexing by aliased field names" do
      @filing.translate do |t|
        t.alias :alias_a, :coverage_from_date, /F3PN/
        t.alias :alias_b, :coverage_through_date, /F3PN/
        t.combine(:row => /F3PN/, :field => :combined) do |row|
          Date.parse(row[:alias_b]) - Date.parse(row[:alias_a])
        end
      end
      lambda {
        @filing.summary
      }.should_not raise_error
    end

  end
  
  describe ".alias" do
    
    before do
      @translator = Fech::Translator.new
    end
    
    it "should add the given alias to @aliases" do
      @translator.alias(:new_name, :old_name, /hdr/)
      @translator.aliases.should =~ [{:row => /hdr/i, :alias => :new_name, :for => :old_name}]
    end
    
    it "should not require :row" do
      lambda {
        @translator.alias(:new_name, :old_name)
      }.should_not raise_error
      @translator.aliases.should =~ [{:row => /.*/i, :alias => :new_name, :for => :old_name}]
    end
    
  end
  
  describe ".applicable_translation?" do
    
    before do
      @row_type = "SA18"
      @field = "date_coverage_from"
      @translation = Fech::Translator.new.convert(:row => "SA", :field => @field, :version => "7.0") {|v| Date.parse(v)}
    end
    
    it "should return true if row and field are matches for the translation's regexes" do
      Fech::Translator.applicable_translation?(@translation, :row => @row_type, :field => @field).should == true
    end
    
    it "should return false if row, field, or version does not match" do
      Fech::Translator.applicable_translation?(@translation, :row => @row_type, :field => @field, :version => "6.0").should == false
    end
    
    it "should accept non-string values" do
      lambda {
        Fech::Translator.applicable_translation?(@translation, :row => Regexp.new(@row_type), :field => @field.to_s)
      }.should_not raise_error
    end
    
    it "should accept match parameters as a single opts hash" do
      lambda {
        Fech::Translator.applicable_translation?(@translation, {:row => Regexp.new(@row_type), :field => @field.to_s})
      }.should_not raise_error
      Fech::Translator.applicable_translation?(@translation, {:row => Regexp.new(@row_type), :field => @field.to_s}).should == true
    end
    
  end
  
  describe ".get_translations" do
    
    before do
      @translator = Fech::Translator.new
      @translator.convert(:row => "sa", :field => :date_coverage_from) {|v| Date.parse(v)}
      @translator.convert(:row => "sa", :field => :date_coverage_to) {|v| Date.parse(v)}
      @translator.convert(:row => "sb", :field => /date.*/) {|v| Date.parse(v)}
    end
    
    it "should return only translations that match the parameters" do
      @translator.get_translations(:row => "sa").size.should == 2
      @translator.get_translations(:row => "sb").size.should == 1
    end
    
    it "should memoize output" do
      Fech::Translator.expects(:applicable_translation?).times(3).returns(true)
      @translator.get_translations(:row => "sa")
      @translator.get_translations(:row => "sa")
    end
    
    it "should only memoize based on unique key" do
      Fech::Translator.expects(:applicable_translation?).times(6).returns(true)
      @translator.get_translations(:row => "sa")
      @translator.get_translations(:row => "sb")
    end
    
  end
  
  describe "#add_default_translations" do
    
    before do
      @translator = Fech::Translator.new(:include => [:names])
    end
    
    it "should add all specified translations by default" do
      @translator.translations.size.should > 0
    end
    
  end
  
end