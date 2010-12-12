$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'

require File.expand_path("../../lib/historian", __FILE__)

begin
  require 'rubygems'
  require 'spackle'
  Spackle.init :with => :rspec_formatter
rescue LoadError
  puts "spackle gem not found -- continuing"
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end
