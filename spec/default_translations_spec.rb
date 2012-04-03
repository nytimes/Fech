require 'spec_helper'

def stub_file(filing_id=723604)
  Fech::Filing.any_instance.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', "#{filing_id}.fec"))
end

def unstub_file
  Fech::Filing.any_instance.unstub(:file_path)
end

describe Fech::DefaultTranslations do
  
  before do
    stub_file
  end
  
  after do
    unstub_file
  end
  
  describe ".names" do
    
    it "should add name translations to default translation set" do
      filing = Fech::Filing.new(723604, :translate => :names)
      filing.translator.translations.size.should > 0
    end
    
    it "should combine name components into aggregate name fields" do
      filing = Fech::Filing.new(723604, :translate => :names)
      Fech::Mapped.any_instance.stubs(:contributor_prefix).returns("Mr.")
      Fech::Mapped.any_instance.stubs(:contributor_first_name).returns("John")
      Fech::Mapped.any_instance.stubs(:contributor_middle_name).returns("Charles")
      Fech::Mapped.any_instance.stubs(:contributor_last_name).returns("Smith")
      Fech::Mapped.any_instance.stubs(:contributor_suffix).returns("III")
      filing.rows_like(/sa/).first.contributor_name.should == "Mr. John Charles Smith III"
    end
  
    it "should split an aggregate name into its component parts" do
      stub_file(97405)
      filing = Fech::Filing.new(97405, :translate => :names)
      filing.filing_version.should == "5.00"
      row = filing.rows_like(/sa/).first
      row.contributor_prefix.should == "Mr."
      row.contributor_first_name.should == "Steve"
      row.contributor_middle_name.should == ""
      row.contributor_last_name.should == "Aaker"
      row.contributor_suffix.should == ""
    end
    
  end
  
  describe ".dates" do
    
    before do
      @filing = Fech::Filing.new(723604, :translate => :dates)
    end
    
    it "should convert values matching YYYYMMDD to Date objects" do
      @filing.rows_like(/sa/).first.contribution_date.should == Date.parse("20110322")
    end
    
    it "should pass all other values through untouched" do
      @filing.rows_like(/sa/).first.contributor_zip_code.should == "298608420"
    end
    
    it "should pass nils through untouched" do
      @filing.rows_like(/sa/).first.conduit_zip.should be_nil
    end
    
  end
  
  describe ".combine_components_into_name" do
    
    before do
      @defaults = Fech::DefaultTranslations.new(Fech::Translator.new)
    end
    
    it "should accept :field as either Array or Symbol" do
      data = {:row => /^sc$/,  :version => /^[6-7]/,   :field => :lender_candidate}
      expect { @defaults.send(:combine_components_into_name, data) }.to_not raise_error
      
      data[:field] = [data[:field]]
      expect { @defaults.send(:combine_components_into_name, data) }.to_not raise_error
    end
    
  end
  
  describe ".split_name_into_components" do
    
    before do
      @defaults = Fech::DefaultTranslations.new(Fech::Translator.new)
    end
    
    it "should accept :field as either Array or Symbol" do
      data = {:row => /^sc$/,  :version => /^[6-7]/,   :field => :lender_candidate}
      expect { @defaults.send(:split_name_into_components, data) }.to_not raise_error
      
      data[:field] = [data[:field]]
      expect { @defaults.send(:split_name_into_components, data) }.to_not raise_error
    end
    
  end
  
end