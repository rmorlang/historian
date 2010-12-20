module Historian
  class ParseError < StandardError; end
end

require "historian/history_file"
require "historian/git"
require "historian/commit_message"

