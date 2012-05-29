require 'net/http'
require 'optparse'

module Fech

  # Fech:SearchResult is a class representing a search result
  # from Fech::Search.
  class SearchResult
    attr_reader :committee_name, :committee_id, :filing_id, :form_type, :period, :date_filed, :description, :amended_by

    # @param [Hash] attrs The attributes of the search result.
    def initialize(attrs)
      @date_format = '%m/%d/%Y'

      @committee_name = attrs[:committee_name]
      @committee_id   = attrs[:committee_id]
      @filing_id      = attrs[:filing_id]
      @form_type      = attrs[:form_type]
      @period         = parse_period(attrs[:period])
      @date_filed     = Date.strptime(attrs[:date_filed], @date_format)
      @description    = attrs[:description]
      @amended_by     = attrs[:amended_by]
    end

    # Parse the string representing a filing period.
    # @param [String] period a string representing a filing period
    # @return [Hash, nil] a hash representing the start and end
    # of a filing period.
    def parse_period(period)
      return if period.nil?
      from, to = period.split('-')
      from = Date.strptime(from, @date_format)
      to = Date.strptime(to, @date_format)
      {:from => from, :to => to}
    end

    # The Fech filing object for this search result
    # @return [Fech::Filing]
    def filing
      @filing ||= Fech::Filing.new(self.filing_id)
    end
  end


  # Fech::Search is an interface for the FEC's electronic filing search
  # (http://www.fec.gov/finance/disclosure/efile_search.shtml)
  class Search

    # @param [Hash] search_params a hash of parameters to be
    # passed to the search form.
    def initialize(search_params={})
      @search_params = make_params(search_params)
      @search_url = 'http://query.nictusa.com/cgi-bin/dcdev/forms/'
      @response = search
    end

    # Convert the search parameters passed to @initialize to use
    # the format and keys needed for the form submission.
    # @return [Hash]
    def make_params(search_params)
      {
        'comid' => search_params[:committee_id] || '',
        'name' => search_params[:committee_name] || '',
        'state' => search_params[:state] || '',
        'party' => search_params[:party] || '',
        'type' => search_params[:committee_type] || '',
        'rpttype' => search_params[:report_type] || '',
        'date' => search_params[:date] ? search_params[:date].strftime('%m/%d/%Y') : '',
        'frmtype' => search_params[:form_type] || ''
      }
    end

    # Performs the search of the FEC's electronic filing database.
    def search
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 5000
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(@search_params)
      @response = http.request(request)
    end

    # A parsed URI for the search
    def uri
      uri = URI.parse(@search_url)
    end

    def body
      @response ? @response.body : nil
    end

    # The results page is formatted differently depending
    # on whether the search includes a date. Use the correct
    # method for parsing the results depending on whether
    # a date was used in the search. Will return an array of
    # results if called directly, or will yield the results one
    # by one if a block is passed.
    def results(&block)
      if @search_params['date'] != ''
        results_from_date_search(&block)
      else
        results_from_nondate_search(&block)
      end
    end

    # Parse the results from a search that does not include a date.
    # Will return an array of results if called directly, or will
    # yield the results one by one if a block is passed.
    def results_from_nondate_search(&block)
      parsed_results = []
      regex = /<DT>(?<content>.*?)<P/m
      match = body.match regex
      content = match['content']
      committee_sections = content.split(/<DT>/)
      committee_sections.each do |section|
        data = parse_committee_section(section)
        data.each do |result|
          search_result = SearchResult.new(result)

          if block_given?
            yield search_result
          else
            parsed_results << search_result
          end
        end
      end
      block_given? ? nil : parsed_results
    end

    # For results of a search that does not include a date, parse
    # the section giving information on the committee that submitted
    # the filing.
    # @param [String] section
    def parse_committee_section(section)
      data = []
      section.gsub!(/^<BR>/, '')
      rows = section.split(/\n/)
      committee_data = parse_committee_row(rows.first)
      rows[1..-1].each do |row|
        data << committee_data.merge(parse_filing_row(row))
      end
      data
    end

    # Parse the results from a search that includes a date.
    # Will return an array of results if called directly, or will
    # yield the results one by one if a block is passed.
    def results_from_date_search(&block)
      parsed_results = []
      results = body.scan(/<DT>(.*)\n(.*)/)
      results.each do |result|
        committee, filing = result
        data = parse_committee_row(committee).merge(parse_filing_row(filing))
        search_result = SearchResult.new(data)

        if block_given?
          yield search_result
        else
          parsed_results << search_result
        end
      end
      block_given? ? nil : parsed_results
    end

    # For results of a search that includes a date, parse
    # the portion of the results with information on the
    # committee that submitted the filing.
    # @param [String] row
    # @return [Hash] the committee name and ID
    def parse_committee_row(row)
      regex = /
              '>
              (?<committee_name>.*?)
              \s-\s
              (?<committee_id>C\d{8})
              /x
      match = row.match regex
      {:committee_name => match['committee_name'], :committee_id => match['committee_id']}
    end

    # Parse a result row with information on the filing itself.
    # @param [String] row
    # @return [Hash] the filing ID, form type, period, date filed, description
    # and, optionally, the filing that amended this filing.
    def parse_filing_row(row)
      regex = /
              FEC-(?<filing_id>\d+)
              \s
              Form
              \s
              (?<form_type>F.*?)
              \s\s-\s
              (?:period\s(?<period>[-\/\d]+),\s)?
              filed
              \s
              (?<filed>[\/\d]+)
              \s
              (?:-\s
               (?<filing_description>.*?)
               (?:$|<BR>.*?FEC-(?<amendment>\d+))
              )?
              /x
      match = row.match regex
      {:filing_id => match['filing_id'],
       :form_type => match['form_type'],
       :period => match['period'],
       :date_filed => match['filed'],
       :description => match['filing_description'],
       :amended_by => match['amendment']
      }
    end

  end
end

