require 'open-uri'

module Fech

    # Fech::Committee provides a way to list all the electronic filing IDs
    # for a given committee.
    class Committee
        attr_accessor :committee_id

        # Create a new Committee object.
        def initialize(committee_id)
            @committee_id = committee_id
            @page = nil
        end

        # Parse the electronic filings page for filing IDs.
        def filing_ids
            filing_list_page.scan(/'(\d+)\/'/).flatten
        end

        # Get the content of the electronic filings page.
        def filing_list_page
            if @page.nil?
                @page = open(filings_url).read
            else
                @page
            end
        end

        def filings_url
            "http://query.nictusa.com/cgi-bin/dcdev/forms/#{committee_id}/"
        end

    end
end
