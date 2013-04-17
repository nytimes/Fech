module Fech
  class SenateFiling < Filing
    def filing_url
      "http://query.nictusa.com/senate/posted/#{filing_id}.fec"
    end
  end
end
