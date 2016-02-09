# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'afasgem/version'

Gem::Specification.new do |spec|
  spec.name          = "afasgem"
  spec.version       = Afasgem::VERSION
  spec.authors       = ["Subhi Dweik"]
  spec.email         = ["subhime@gmail.com"]

  spec.summary       = %q{A gem that wraps basic afas api functionality}
  spec.homepage      = "https://github.com/Bonemind/Afasgem"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'savon', '>= 2.11.1'
  spec.add_dependency 'httpclient'
  spec.add_dependency 'rubyntlm', '~> 0.3.2'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'pry-doc'
end
