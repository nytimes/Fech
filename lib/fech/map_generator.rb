module Fech
  
  # Helper class to generate mapping hashes from source csv data.
  # Needed to rebuild rendered_maps.rb with new source data, not used
  # in main gem.
  #   rake fech:maps
  class MapGenerator
    
    attr_accessor :map
    FILING_VERSIONS   = ["8.0", "7.0", "6.4", "6.3", "6.2", "6.1",
                         "5.3", "5.2", "5.1", "5.0", "3"]
    BASE_ROW_TYPES    = ["HDR", "F1", "F1M", "F2", "F24", "F3", "F3L", "F3P", "F3P31", "F3PS", "F3S", "F3X", 
                         "F4", "F5", "F56", "F57", "F9", "F91", "F92", "F93", "F94",
                         "SchA", "SchB", "SchC", "SchC1", "SchC2", "SchD", "SchE", 
                         "SchF", "TEXT"]
    ROW_TYPE_MATCHERS = {
      "HDR"    => FechUtils::ROW_TYPES[:hdr],
      "F1"     => FechUtils::ROW_TYPES[:f1],
      "F1M"     => FechUtils::ROW_TYPES[:f1m],
      "F2"    => FechUtils::ROW_TYPES[:f2],
      "F24"    => FechUtils::ROW_TYPES[:f24],
      "F3"     => FechUtils::ROW_TYPES[:f3],
      "F3L"    => FechUtils::ROW_TYPES[:f3l],
      "F3P"    => FechUtils::ROW_TYPES[:f3p],
      "F3S"    => FechUtils::ROW_TYPES[:f3s],
      "F3P31"  => FechUtils::ROW_TYPES[:f3p31],
      "F3PS"   => FechUtils::ROW_TYPES[:f3ps],
      "F3X"   => FechUtils::ROW_TYPES[:f3x],
      "F4"   => FechUtils::ROW_TYPES[:f4],
      "F5"    => FechUtils::ROW_TYPES[:f5],
      "F56"    => FechUtils::ROW_TYPES[:f56],
      "F57"    => FechUtils::ROW_TYPES[:f57],
      "F9"     => FechUtils::ROW_TYPES[:f9],
      "F91"    => FechUtils::ROW_TYPES[:f91],
      "F92"    => FechUtils::ROW_TYPES[:f92],
      "F93"    => FechUtils::ROW_TYPES[:f93],
      "F94"    => FechUtils::ROW_TYPES[:f94],
      "SchA"   => FechUtils::ROW_TYPES[:sa],
      "SchB"   => FechUtils::ROW_TYPES[:sb],
      "SchC"   => FechUtils::ROW_TYPES[:sc],
      "SchC1"  => FechUtils::ROW_TYPES[:sc1],
      "SchC2"  => FechUtils::ROW_TYPES[:sc2],
      "SchD"   => FechUtils::ROW_TYPES[:sd],
      "SchE"   => FechUtils::ROW_TYPES[:se],
      "SchF"   => FechUtils::ROW_TYPES[:sf],
      "TEXT"   => FechUtils::ROW_TYPES[:text],
    }
    
    # Goes through all version header summary files and generates
    # row map files for each type of row inside them.
    def self.convert_header_file_to_row_files(source_dir)
      data = {}
      hybrid_data = {}
      
      ignored_fields = File.open(ignored_fields_file(source_dir)).readlines.map { |l| l.strip }
      
      # Create a hash of data with an entry for each row type found in the source
      # version summary files. Each row has an entry for each version map that
      # exists for it. If maps for two different versions are identical, they
      # are combined.
      FILING_VERSIONS.each do |version|
        Fech::Csv.foreach(version_summary_file(source_dir, version)) do |row|
          # Each row of a version summary file contains the ordered list of
          # column names.
          data[row.first] ||= {}
          hybrid_data[row.first] ||= {}
          row_version_data = remove_ignored_fields(row, ignored_fields)

          # Check the maps for this row type in already-processed versions.
          # If this map is identical to a previous map, tack this version on to
          # to it instead of creating a new one.
          data[row.first][version] = row_version_data
          data[row.first].each do |k, v|
            # skip the row we just added
            
            next if k == version
            if v == row_version_data
              # Create the new hybrid entry
              hybrid_data[row.first]["#{k}|#{version}"] = row_version_data
              
              # Delete the old entry, and the one for this version only
              data[row.first].delete(k)
              data[row.first].delete(version)
            end
          end
          data[row.first].update(hybrid_data[row.first])
        end
      end
      
      # Go through each row type and create a base map management file that
      # will serve as a template for organizing which fields are the same
      # between versions. This file will need to then be arranged by hand to
      # clean up the data. Each row will represent a column across versions,
      # each column a unique map for that row for one or more versions.
      data.each do |row_type, row_data|
        file_path = write_row_map_file(source_dir, row_type)
        next unless File.exists?(file_path)
        File.open(file_path, 'w') do |f|
          f.write('canonical')
          
          to_transpose = []
          row_data.sort.reverse.each do |version, version_data|
            to_transpose << ["^#{version}", version_data.each_with_index.collect {|x, idx| idx+1}].flatten
            to_transpose << [nil, version_data].flatten
          end
          
          # standardize row size
          max_size = to_transpose.max { |r1, r2| r1.size <=> r2.size }.size
          to_transpose.each { |r| r[max_size - 1] ||= nil }
          transposed = to_transpose.transpose
          
          transposed.each do |transposed_data|
            transposed_data.collect! {|x| x.to_s.gsub(/\r/, ' ')}
            canonical = transposed_data[1] # first description
            if canonical
              canonical = canonical.gsub(/\{.*\}/, "").gsub(/[ -\.\/\(\)]/, "_").gsub(/_+/, "_").gsub(/(_$)|(^_)/, "").downcase
              transposed_data = [canonical, transposed_data].flatten
            end
            f.write(transposed_data.join(','))
            f.write("\n")
          end
        end
      end

    end
    
    # Generates the mapping for each row type in BASE_ROW_TYPES, writes them out
    # to file for inclusion in the gem.
    def self.dump_row_maps_to_ruby(source_dir, file_path)
      File.open(file_path, 'w') do |f|
        f.write("# Generated automatically by Fech::MapGenerator.\n\n")
        f.write("# RENDERED_MAPS contains an entry for each supported row type, which in turn:\n")
        f.write("#   contain an entry for each distinct map between a row's labels and the\n")
        f.write("#   indexes where their values can be found.\n")
        f.write("module Fech\n")
        f.write("  RENDERED_MAPS = {\n")
        BASE_ROW_TYPES.each do |row_type|
          f.write("    \"#{ROW_TYPE_MATCHERS[row_type].source}\" => {\n")
          generate_row_map_from_file(source_dir, row_type).each do |k, v|
            f.write("      \'#{k}' => [#{v.map {|x| x.to_s.gsub(/^\d+_?/, "") }.collect {|x| (x.nil? || x == "") ? "nil" : ":#{x}" }.join(', ') }],\n")
          end
          f.write("    },\n")
        end
        f.write("  }\n")
        f.write("end")
      end
    end

    # For a given row type, parses its source file and returns
    # a mapping object for it.
    def self.generate_row_map_from_file(source_dir, row_type)
      versions = []
      version_indexes = []
      data = {}
      text = open(row_map_file(source_dir, row_type)).read
      split_char = text.index(/\r/) ? /\r/ : /\n/
      rows = text.split(split_char).collect {|x| x.split(',')}
      rows.each do |row|
        row = row.collect {|x| x.gsub("\n", "")}
        if row.first.nil?
          require 'ruby-debug'; debugger
        end
        if row.first.downcase == "canonical"
          versions = row[1..-1].uniq.collect {|x| x unless (x.nil? || x.empty?)}.compact
          row.each_with_index {|x, ind| version_indexes << ind unless (x.nil? || x.empty?)}.slice!(1)
          version_indexes.slice!(0, 1)
          versions.each {|x| data[x] = [] }
          
        elsif row.first.size > 0
          canonical = row.first
          
          versions.zip(version_indexes).each do |version, row_index|
            index = row[row_index]
            data[version][index.to_i - 1] = canonical.to_sym if index.to_i > 0
          end
        end
      end
    
      row_map = {}
      data.each {|key, value| row_map[key] = value}
      row_map
    end
    
    # Remove both the row type from the beginning of the row,
    # and any fields marked as "ignore" in sources/headers/ignore.csv
    def self.remove_ignored_fields(row, ignore)
      data = row[1..-1].compact # strip off the row type
      data.reject { |f| ignore.include?(f) }
    end
    
    def self.row_map_file(source_dir, row_type)
      File.join(source_dir, row_type + '.csv')
    end
    
    def self.ignored_fields_file(source_dir)
      File.join(source_dir, 'headers', 'ignore.csv')
    end
    
    def self.version_summary_file(source_dir, version)
      File.join(source_dir, 'headers', version + '.csv')
    end
    
    def self.write_row_map_file(source_dir, row_type)
      File.join(source_dir, 'rows', row_type + '.csv')
    end
  
  end
end
