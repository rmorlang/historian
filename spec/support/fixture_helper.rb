def fixture_filename(name)
  File.expand_path("../../fixtures/#{name}", __FILE__)
end

def fixture(name)
  File.read(fixture_filename name).strip
end

