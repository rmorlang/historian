# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "historian/version"

Gem::Specification.new do |s|
  s.name        = "historian"
  s.version     = Historian::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Richard Lee-Morlang"]
  s.email       = ["rick@lee-morlang.com"]
  s.homepage    = "https://github.com/rleemorlang/historian"
  s.summary     = %q{Automatically extract information from git commit messages and update your project's history file.}
  s.description = %q{Historian uses git commit hooks to inject itself into Git's commit workflow. Historian checks your commit messages for certain markup tokens. If found, it updates your project's history file, and amends your commit with it, while also stripping out the markup.}

  #s.rubyforge_project = "historian"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "thor"
  s.add_dependency "project_scout", ">= 0.0.2"

  s.add_development_dependency "rspec", "~> 2.3.0"
  s.add_development_dependency "bundler"
  s.add_development_dependency "autotest"
end
