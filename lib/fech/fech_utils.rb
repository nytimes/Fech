# Contains helper functions and static variables used by various
# Fech classes.
module FechUtils
  
  # All supported row types pointed to regular expressions that will correctly
  # match that row type in the wild.
  ROW_TYPES = {
    :hdr   => /^hdr$/i,
    :f24   => /^f24/i,
    :f3p   => /(^f3p$)|(^f3p[^s|3])/i,
    :f3s   => /^f3s/i,
    :f3p31 => /^f3p31/i,
    :f3ps  => /^f3ps/i,
    :f3x  => /^f3x/i,
    :f5    => /^f5[na]/i,
    :f56   => /^f56/i,
    :f57   => /^f57/i,
    :sa    => /^sa/i,
    :sb    => /^sb/i,
    :sc    => /^sc[^1-2]/i,
    :sc1   => /^sc1/i,
    :sc2   => /^sc2/i,
    :sd    => /^sd/i,
    :se    => /^se/i,
    :sf    => /^sf/i,
    :text  => /^text/i,
  }
  
  # Converts symbols and strings to Regexp objects for use in regex-keyed maps.
  # Assumes that symbols should be matched literally, strings unanchored.
  # @param [String,Symbol,Regexp] label the object to convert to a Regexp
  def regexify(label)
    if label.is_a?(Regexp)
      Regexp.new(label.source, Regexp::IGNORECASE)
    elsif label.is_a?(Symbol)
      if ROW_TYPES.keys.include?(label)
        ROW_TYPES[label]
      else
        Regexp.new("^#{label.to_s}$", Regexp::IGNORECASE)
      end
    else
      Regexp.new(Regexp.escape(label.to_s), Regexp::IGNORECASE)
    end
  end

end
