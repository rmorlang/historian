module Historian
  module HistoryFile
    # Example:
    #
    #   history = File.open("History.txt", "w+") # (empty file!)
    #   history.extend Historian::HistoryFile
    #   history.next_version # => "0.0.1"
    #   history.update_history :minor => "added whizbangery",
    #                          :release => "Awesome Release"
    #   history.rewind
    #   puts history.read
    #     ## 0.1.0 Awesome Release - 2010/12/12
    #
    #     ### Minor Changes
    #     * added whizbangery
    #
    # Note that the "w+" mode is critically important if you're
    # extending a File object. The IO instance must be both
    # readable and writeable.

    SECTION_HEADERS = {
      :major => "Major Changes",
      :minor => "Minor Changes",
      :patch => "Bugfixes"
    }

    # The pending changelog for the next release. See also #release_log.
    def changelog
      return "" unless changes?

      log = []
      if @release
        release_string = @release === true ? "" : " " + @release
        date_string = " - " + Time.now.strftime("%Y/%m/%d")
        log << "== #{next_version}#{release_string}#{date_string}"
      else
        log << "== In Git"
      end
      [ :major, :minor, :patch ].each do |significance|
        unless changes[significance].empty?
          log << "\n=== #{SECTION_HEADERS[significance]}"
          changes[significance].each { |change| log << "* #{change}" }
        end
      end
      log.join("\n")
    end

    def changes #:nodoc:
      @changes ||= {
        :major => [],
        :minor => [],
        :patch => []
      }
    end

    # Whether there are changes since the last release
    def changes?
      parse unless parsed?
      changes.find { |(k,v)| !v.empty? }
    end

    # The current (most-recently released) version number in "x.y.z" format
    def current_version
      parse unless parsed?
      @current_version || "0.0.0"
    end

    # The next (upcoming release) version number, based on what
    # pending changes currently exist. Major changes will increment
    # the major number, else minor changes will increment the minor
    # number, else the patch number is incremented.
    def next_version
      parse unless parsed?
      (major, minor, patch) = current_version.split(".").collect { |n| n.to_i }
      if !changes[:major].empty?
        major += 1
        patch = minor = 0
      elsif !changes[:minor].empty?
        minor += 1
        patch = 0
      else
        patch += 1
      end
      "%d.%d.%d" % [ major, minor, patch ]
    end

    # If a release was just performed, this will return the changelog
    # of the release. Otherwise, this is always nil.
    def release_log
      parse unless parsed?
      @release_log
    end

    # Returns the name of the current release, either as parsed
    # from the history file, or as provided if a release was
    # recently performed.
    def current_release_name
      parse unless parsed?
      @current_release_name
    end

    # Update the release history with new release information.
    # Accepts a hash with any (or all) of four key-value pairs.
    # [:major] a message describing a major change
    # [:major] a message describing a minor change
    # [:patch] a message describing a bugfix or other tiny change
    # [:release] indicates this history should be updated for a new release, if present. If true, the release has no name, but if a string is provided the release will be annotated with the string
    #
    # To add multiple history entries of the same type, call
    # this method mutiple times.
    #
    # *Note*: this method rewrites the entire IO instance to
    # prepend the new history information.
    def update_history(history)
      parse unless parsed?
      @release = history.delete(:release)
      history.each do |(significance,message)|
        changes[significance] << message
      end
      rewrite
    end


  protected

    def rewrite #:nodoc:
      rewind
      puts changelog
      puts ["\n"] * 2
      puts @buffer
      truncate pos
      if @release
        @release_log = changelog
        @current_release_name = @release if @release.kind_of?(String)
        parse
        @release = nil
        @changes = nil
      end
    end

    def parsed? #:nodoc:
      @parsed
    end

    def parse #:nodoc:
      rewind
      @buffer = []
      @release_log = []
      state = :gathering_current_history
      significance = nil
      each_line do |line|
        if state == :gathering_current_history
          case line
          when /^== ([0-9]+\.[0-9]+\.[0-9]+)(.*)/
            state = :gathering_previous_release_log
            @release_log << line
            @buffer << line
            @current_version = $1
            if $2 =~ %r{ (.*) - [0-9]{4}/[0-9]{2}/[0-9]{2}}
              @current_release_name = $1
            end
          when /^=== Bugfixes$/
            significance = :patch
          when /^\* (.+)$/
            changes[significance] << $1
          end
        elsif state == :gathering_previous_release_log
          if line =~ /^== ([0-9]+\.[0-9]+\.[0-9]+)(.*)/
            state = :gathering_remainder
          else
            @release_log << line
          end
          @buffer << line
        else
          @buffer << line
        end
      end
      @release_log = @release_log.join
      @parsed = true
    end
  end
end
