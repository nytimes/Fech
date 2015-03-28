# Contains helper functions and static variables used by various
# Fech classes.
module FechUtils

  # All supported row types pointed to regular expressions that will correctly
  # match that row type in the wild. If multiple matches exist, Fech will match
  # the longest regex pattern found.
  ROW_TYPES = {
    :hdr   => /^hdr$/i,
    :f1    => /^f1[an]/i,
    :f13   => /^f13[an]/i,
    :f132  => /^f132/i,
    :f133  => /^f133/i,
    :f1m   => /(^f1m[a|n])/i,
    :f1s   => /^f1s/i,
    :f2    => /(^f2$)|(^f2[^4])/i,
    :f24   => /(^f24$)|(^f24[an])/i,
    :f3    => /^f3[a|n|t]/i,
    :f3l   => /^f3l[a|n]/i,
    :f3p   => /(^f3p$)|(^f3p[^s|3])/i,
    :f3s   => /^f3s/i,
    :f3p31 => /^f3p31/i,
    :f3ps  => /^f3ps/i,
    :f3x   => /(^f3x$)|(^f3x[ant])/i,
    :f3z   => /^f3z/i,
    :f4    => /^f4[na]/i,
    :f5    => /^f5[na]/i,
    :f56   => /^f56/i,
    :f57   => /^f57/i,
    :f6    => /(^f6$)|(^f6[an])/i,
    :f65   => /^f65/i,
    :f7    => /^f7[na]/i,
    :f76   => /^f76/i,
    :f9    => /^f9/i,
    :f91   => /^f91/i,
    :f92   => /^f92/i,
    :f93   => /^f93/i,
    :f94   => /^f94/i,
    :f99   => /^f99/i,
    :h1    => /^h1/i,
    :h2    => /^h2/i,
    :h3    => /^h3/i,
    :h4    => /^h4/i,
    :h5    => /^h5/i,
    :h6    => /^h6/i,
    :sa    => /^sa/i,
    :sa3l  => /^sa3l/i,
    :sb    => /^sb/i,
    :sc    => /^sc[^1-2]/i,
    :sc1   => /^sc1/i,
    :sc2   => /^sc2/i,
    :sd    => /^sd/i,
    :se    => /^se/i,
    :sf    => /^sf/i,
    :sl    => /^sl/i,
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
