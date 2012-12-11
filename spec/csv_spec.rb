require 'spec_helper'

describe Fech::Csv do
  
  before do
    @filing = Fech::Filing.new(723604, :csv_parser => Fech::CsvDoctor)
    @filing.stubs(:file_path).returns(File.join(File.dirname(__FILE__), 'data', '723604.fec'))
  end

  it "should parse a filing using CsvDoctor" do
    @filing.rows_like(//) { |row| nil }
  end

end
