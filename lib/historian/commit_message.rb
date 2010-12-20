require 'ostruct'

class Historian::CommitMessage
  attr_reader :line, :token, :suppressed

  def initialize(line)
    if line =~ /^([!bmM])(#?):(.*[0-9a-zA-Z].*)$/
      @token = $1
      @suppressed = true if $2 == "#"
      @line = $3
    else
      @line = line
    end
  end

  def significance
    case token
    when "b"; :patch
    when "m"; :minor
    when "M"; :major
    when "!"; :release
    end
  end

  def suppressed?
    @suppressed == true
  end

  def to_s
    line
  end

  def to_message_s
    line.gsub /^\W*/, '' if significance
  end

  def self.parse_line(line)
    new line
  end
end
