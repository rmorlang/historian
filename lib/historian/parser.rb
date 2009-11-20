module Historian
  class Parser
    attr_reader :data, :config
    attr_accessor :index
    def initialize(io, config)
      @config = config
      @data = io.readlines
      @index = 0
    end

    def prepare_to_scan
      @index = 0
    end

    def pending_release_label
      "In Git"
    end

    def release_string(release)
      "== #{release}"
    end

    def section_string(section = "")
      section =  config.map[section] || section
      "=== #{section.to_s}"
    end

    def list_string(list_entry)
      "* #{list_entry}"
    end

    def compare_section_keys(keys, options)
      line = options[:against]
      return nil unless line =~ /^#{section_string '(.*)' }$/
      section = $1
      keys.each do |key|
        if key == section || config.map[key] == section
          return config.map.invert[key] || key
        end
      end
      nil
    end

    def at_section_end?
      if data[index] =~ /^\s+$/
        search_index = index - 1
        5.times do |offset|
          return false if data[search_index] =~ /^\s+$/
          return true if data[search_index] =~ /^\* \S+/
        end
      end
    end

    def scan_for_release(release = nil)
      pattern = /#{release_string(release)}/
      self.index = data.find_index { |line| line =~ pattern }
      if self.index
        return self.data[self.index]
      else
        self.index = data.count
        return nil
      end
    end

    def each_line_in_release
      while index < (data.count-1)
        line = data[index]
        case line
        when /^== /
          #self.index -= 1
          break
        else
          yield line
        end
        self.index += 1
      end
    end

    def status(release = nil)
      prepare_to_scan
      buffer = []
      buffer << scan_for_release(release)
      self.index += 1
      each_line_in_release { |line| buffer << line }
      buffer.compact!
      while (buffer.last =~ /^\s*$/)
        buffer.pop
      end
      buffer.empty? ? nil : buffer.join
    end

    def insert(string = "")
      self.data.insert(index, string.to_s + "\n")
      self.index += 1
    end

    def add(additions)
      prepare_to_scan
      release_line = scan_for_release
      case release_line
      when /#{release_string(pending_release_label)}/
        self.index += 1
      else
        insert release_string(pending_release_label)
        insert 
      end

      # start looking for matching sections and append to them
      section_key = nil
      each_line_in_release do |line|
        if section_key && at_section_end?
          lines = [additions.delete(section_key)].flatten
          lines.each { |line| insert list_string(line) }
          section_key = nil
        elsif section_key.nil?
          section_key = compare_section_keys additions.keys, :against => line
        end
      end

      unless additions.empty?
        additions.each do |key, lines|
         lines = [lines].flatten
         insert section_string(config.map[key] || key)
         lines.each { |line| insert list_string(line) }
         insert
        end
      end
      self.data
    end

  end
end
