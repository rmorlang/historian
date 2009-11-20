$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'historian'
require 'spec'
require 'spec/autorun'
begin
  require 'rubygems'
  require 'spackle'
  Spackle.init :with => :spec_formatter
rescue LoadError
  puts "spackle gem not found -- continuing"
end

Spec::Runner.configure do |config|
end
