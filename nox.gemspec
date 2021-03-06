# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "nox/version"

Gem::Specification.new do |s|
  s.name        = "nox"
  s.version     = Nox::VERSION
  s.authors     = ["keithpitt"]
  s.email       = ["me@keithpitt.com"]
  s.homepage    = ""
  s.summary     = %q{Ruby adapter for Nox}
  s.description = %q{Ruby adapter for Nox}

  s.rubyforge_project = "nox"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Development dependencies
  %w(rake minitest purdytest webmock).each { |gem| s.add_development_dependency(gem) }

  # s.add_runtime_dependency "rest-client"
end
