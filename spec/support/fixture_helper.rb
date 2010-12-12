
def fixture(name)
  File.read(File.expand_path("../../fixtures/#{name}", __FILE__)).strip
end

