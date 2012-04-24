require 'spec_helper'

describe Fech::Search do

  describe "search" do

    before do
      @date = Date.new(2012, 4, 22)
      @cid = 'C00490045'
      @date_search = Fech::Search.new({:date => @date})
      @committee_id_search = Fech::Search.new({:committee_id => @cid})
      @state_search = Fech::Search.new({:state => 'AK'})
      @party_search = Fech::Search.new({:party => 'CIT'})
      @date_and_party_search = Fech::Search.new({:date => @date, :party => 'REP'})
      @date_and_report_type_search = Fech::Search.new({:date => @date, :report_type => 'M4'})
    end

    it "should return an array" do
      results = @date_search.results
      results.is_a?(Array).should == true

      results = @state_search.results
      results.is_a?(Array).should == true

      results = @party_search.results
      results.is_a?(Array).should == true

      results = @date_and_party_search.results
      results.is_a?(Array).should == true

      results = @date_and_report_type_search.results
      results.is_a?(Array).should == true
    end

    it "should return filings filed on 2012-04-22" do
      results = @date_search.results
      dates = results.map(&:date_filed).uniq
      dates.length.should == 1
      dates.first.should == @date

      results = @date_and_party_search.results
      dates = results.map(&:date_filed).uniq
      dates.length.should == 1
      dates.first.should == @date

      results = @date_and_report_type_search.results
      dates = results.map(&:date_filed).uniq
      dates.length.should == 1
      dates.first.should == @date
    end

    it "should return filings from C00490045" do
      results = @committee_id_search.results
      cids = results.map(&:committee_id).uniq
      cids.length.should == 1
      cids.first.should == @cid 
    end

    it "should return a filing object" do
      results = @date_search.results
      filing = results.first.filing
      filing.class.should == Fech::Filing
    end

  end

end
